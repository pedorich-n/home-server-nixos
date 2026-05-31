{
  config,
  autheliaLib,
  networkingLib,
  pkgs,
  ...
}:
{
  sops.templates = {
    "olivetin/oidc.yaml" = {
      owner = config.services.olivetin.user;
      group = config.services.olivetin.group;
      file = pkgs.writers.writeYAML "olivetin-oidc.yaml" {
        authOAuth2RedirectURL = "${networkingLib.mkUrl "olivetin"}/oauth/callback";
        authOAuth2Providers = {
          authelia = {
            name = "authelia";
            title = "Authelia";
            clientId = config.sops.placeholder."authelia/oidc/olivetin/client_id";
            clientSecret = config.sops.placeholder."authelia/oidc/olivetin/client_secret_raw";
            authURL = "${autheliaLib.issuerUrl}/api/oidc/authorization";
            tokenURL = "${autheliaLib.issuerUrl}/api/oidc/token";
            whoamiUrl = "${autheliaLib.issuerUrl}/api/oidc/userinfo";
            scopes = [
              "openid"
              "profile"
              "email"
              "group"
            ];
            usernameField = "preferred_username";
            userGroupField = "group";
            icon = "<iconify-icon icon=\"simple-icons:authelia\"></iconify-icon>";
          };
        };

        accessControlLists = {
          name = "admins";
          matchUsergroups = [
            autheliaLib.groups.Admins
          ];
          policy = {
            showDiagnostics = true;
            showLogList = true;
          };
        };

        defaultPolicy = {
          showDiagnostics = false;
          showLogList = false;
        };
      };
    };
  };
}
