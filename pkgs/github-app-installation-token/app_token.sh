# Original code from https://github.com/myoung34/docker-github-actions-runner/blob/cd0ae04c4590445aadc4af3a83f482bb7f4ad0f6/app_token.sh
#
# Request an ACCESS_TOKEN to be used by a GitHub APP
# Environment variable that need to be set up:
# * APP_ID, the GitHub's app ID
# * APP_PRIVATE_KEY, the content of GitHub app's private key in PEM format.
# * APP_LOGIN, the login name used to install GitHub's app
#
# https://github.com/orgs/community/discussions/24743#discussioncomment-3245300
#

API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
CONTENT_LENGTH_HEADER="Content-Length: 0"

APP_INSTALLATIONS_URI="https://api.github.com/app/installations"

# JWT parameters based off
# https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app
#
# JWT token issuance and expiration parameters
JWT_IAT_DRIFT=60
JWT_EXP_DELTA=600

JWT_JOSE_HEADER='{
    "alg": "RS256",
    "typ": "JWT"
}'

build_jwt_payload() {
  now=$(date +%s)
  iat=$((now - JWT_IAT_DRIFT))
  jq -c \
    --arg iat_str "${iat}" \
    --arg exp_delta_str "${JWT_EXP_DELTA}" \
    --arg app_id_str "${APP_ID}" \
    '
        ($iat_str | tonumber) as $iat
        | ($exp_delta_str | tonumber) as $exp_delta
        | ($app_id_str | tonumber) as $app_id
        | .iat = $iat
        | .exp = ($iat + $exp_delta)
        | .iss = $app_id
    ' <<<"{}" | tr -d '\n'
}

base64url() {
  base64 | tr '+/' '-_' | tr -d '=\n'
}

rs256_sign() {
  openssl dgst -binary -sha256 -sign <(echo "$1")
}

request_access_token() {
  jwt_payload=$(build_jwt_payload)
  encoded_jwt_parts=$(base64url <<<"${JWT_JOSE_HEADER}").$(base64url <<<"${jwt_payload}")
  encoded_mac=$(echo -n "${encoded_jwt_parts}" | rs256_sign "${APP_PRIVATE_KEY}" | base64url)
  generated_jwt="${encoded_jwt_parts}.${encoded_mac}"

  auth_header="Authorization: Bearer ${generated_jwt}"
  app_installations_response=$(
    curl -sX GET \
      -H "${auth_header}" \
      -H "${API_HEADER}" \
      "${APP_INSTALLATIONS_URI}"
  )

  access_token_url=$(echo "${app_installations_response}" | jq --raw-output '.[] | select (.account.login == "'"${APP_LOGIN}"'" and .app_id  == '"${APP_ID}"') .access_tokens_url')

  curl -sX POST \
    -H "${CONTENT_LENGTH_HEADER}" \
    -H "${auth_header}" \
    -H "${API_HEADER}" \
    "${access_token_url}" |
    jq --raw-output .token
}

request_access_token
