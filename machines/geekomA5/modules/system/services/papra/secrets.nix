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
    "papra/oidc.env" = {
      # owner = config.services.papra.user;
      # group = config.services.papra.group;
      file = keyValueFomat.generate "paperless-oidc.env" {
        AUTH_PROVIDERS_CUSTOMS = builtins.toJSON [
          {
            prodiverId = "authelia";
            providerName = "Authelia";
            providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";
            type = "oidc";
            pkce = true;
            clientId = config.sops.placeholder."authelia/oidc/papra/client_id";
            clientSecret = config.sops.placeholder."authelia/oidc/papra/client_secret_raw";
            discoveryUrl = autheliaLib.discoveryUrl;
            scopes = [
              "openid"
              "profile"
              "email"
            ];
          }
        ];
      };
    };
  };
}
