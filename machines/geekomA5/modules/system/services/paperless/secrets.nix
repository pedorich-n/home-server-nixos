{
  config,
  autheliaLib,
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
        PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
          openid_connect = {
            APPS = [
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

    "paperless/smtp.env" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = keyValueFomat.generate "paperless-smtp.env" {
        PAPERLESS_EMAIL_FROM = "Paperless HomeLab <${config.sops.placeholder."paperless/smtp/username"}>";
      };
    };
  };
}
