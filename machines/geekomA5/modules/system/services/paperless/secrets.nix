{
  config,
  autheliaLib,
  authentikLib,
  pkgs,
  ...
}:
let
  keyValueFomat = pkgs.formats.keyValue { };
in
{
  sops.templates = {
    "paperless/oidc.env" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = keyValueFomat.generate "paperless-oidc.env" {
        # See https://docs.goauthentik.io/integrations/services/paperless-ngx/
        PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
          openid_connect = {
            APPS = [
              {
                provider_id = "authentik";
                name = "Authentik";
                client_id = config.sops.placeholder."paperless/client_id";
                secret = config.sops.placeholder."paperless/client_secret";
                settings = {
                  server_url = authentikLib.mkIssuerUrl "paperless";
                };
              }
              {
                provider_id = "authelia";
                name = "Authelia";
                client_id = config.sops.placeholder."authelia/oidc/paperless/client_id";
                secret = config.sops.placeholder."authelia/oidc/paperless/client_secret_raw";
                settings = {
                  server_url = autheliaLib.issuerUrl;
                };
              }
            ];
            OAUTH_PKCE_ENABLED = true;
          };
        };
      };
    };
  };
}
