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
        # Despite this being called authHeader it actually also applies to OIDC.
        # This indicates that multiple Olivetin should try to split the groups by comma.
        authHttpHeaderUserGroupSep = ",";
        authOAuth2Providers = {
          authelia = {
            name = "authelia";
            title = "Authelia";
            clientId = config.sops.placeholder."authelia/oidc/olivetin/client_id";
            clientSecret = config.sops.placeholder."authelia/oidc/olivetin/client_secret_raw";
            authUrl = "${autheliaLib.issuerUrl}/api/oidc/authorization";
            tokenUrl = "${autheliaLib.issuerUrl}/api/oidc/token";
            whoamiUrl = "${autheliaLib.issuerUrl}/api/oidc/userinfo";
            scopes = [
              "openid"
              "profile"
              "email"
              "groups_concatenated"
            ];
            usernameField = "preferred_username";
            userGroupField = "groups_concatenated";
            icon = ''<iconify-icon icon="simple-icons:authelia"></iconify-icon>'';
          };
        };
      };
    };
  };
}
