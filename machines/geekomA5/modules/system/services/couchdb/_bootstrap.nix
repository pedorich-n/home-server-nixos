{
  writeShellApplication,
  curl,
  dbNameFile,
  adminUsernameFile,
  userUsernameFile,
  adminPasswordFile,
  userPasswordFile,
  baseUrl,
  bindAddress,
  bindPort,
}:
writeShellApplication {
  name = "couchdb-bootstrap";
  runtimeInputs = [
    curl
  ];

  text = ''
    BASE_URL="${baseUrl}"

    read_secret() {
      local file="$1"
      if [ ! -f "$file" ]; then
        echo "Error: secret file '$file' does not exist" >&2
        exit 1
      fi
      tr -d '\n' < "$file"
    }

    DB_NAME="$(read_secret ${dbNameFile})"
    ADMIN_USERNAME="$(read_secret ${adminUsernameFile})"
    ADMIN_PASSWORD="$(read_secret ${adminPasswordFile})"
    USER_USERNAME="$(read_secret ${userUsernameFile})"
    USER_PASSWORD="$(read_secret ${userPasswordFile})"

    if [ -z "$ADMIN_PASSWORD" ] || [ -z "$USER_PASSWORD" ]; then
      echo "Error: passwords are empty" >&2
      exit 1
    fi

    curl_code() {
      curl -sS -o /dev/null -w "%{http_code}" \
        -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" "$@"
    }

    echo "Waiting for CouchDB at $BASE_URL..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
      code=$(curl_code "$BASE_URL") || true
      if [ "$code" = "200" ]; then
        echo "CouchDB is reachable"
        break
      fi
      attempt=$((attempt + 1))
      sleep 2
    done

    if [ $attempt -ge $max_attempts ]; then
      echo "Timeout waiting for CouchDB" >&2
      exit 1
    fi

    echo "Bootstrapping CouchDB at $BASE_URL"

    echo "Enabling single-node mode..."
    code=$(curl_code -X POST "$BASE_URL/_cluster_setup" \
      -H "Content-Type: application/json" \
      -d "{\"action\":\"enable_single_node\",\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\",\"bind_address\":\"${bindAddress}\",\"port\":${bindPort},\"singlenode\":true}")
    [[ "$code" == "200" || "$code" == "201" ]] || { echo "Failed to enable single-node mode (HTTP $code)"; exit 1; }

    # Create _users database
    code=$(curl_code -X PUT "$BASE_URL/_users")
    [[ "$code" == "201" || "$code" == "412" ]] || { echo "Failed to create _users (HTTP $code)"; exit 1; }

    # Create app database
    code=$(curl_code -X PUT "$BASE_URL/$DB_NAME")
    [[ "$code" == "201" || "$code" == "412" ]] || { echo "Failed to create $DB_NAME (HTTP $code)"; exit 1; }

    # Create user if doesn't exist
    user_id="org.couchdb.user:$USER_USERNAME"
    code=$(curl_code "$BASE_URL/_users/$user_id")

    if [ "$code" = "404" ]; then
      code=$(curl_code -X PUT "$BASE_URL/_users/$user_id" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$USER_USERNAME\",\"password\":\"$USER_PASSWORD\",\"roles\":[],\"type\":\"user\"}")
      [[ "$code" == "201" || "$code" == "202" ]] || { echo "Failed to create user (HTTP $code)"; exit 1; }
      echo "Created user: $USER_USERNAME"
    elif [ "$code" = "200" ]; then
      echo "User exists: $USER_USERNAME"
    else
      echo "Failed to check user (HTTP $code)"
      exit 1
    fi

    # Set database permissions
    code=$(curl_code -X PUT "$BASE_URL/$DB_NAME/_security" \
      -H "Content-Type: application/json" \
      -d "{\"admins\":{\"names\":[],\"roles\":[]},\"members\":{\"names\":[\"$USER_USERNAME\"],\"roles\":[]}}")
    [[ "$code" == "200" || "$code" == "201" || "$code" == "202" ]] || { echo "Failed to set permissions (HTTP $code)"; exit 1; }

    echo "✓ Setup complete!"
  '';
}
