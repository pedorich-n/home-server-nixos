{
  config,
  pkgs,
  networkingLib,
  ...
}:
let
  shared = import ../_shared.nix;

  yamlFormat = pkgs.formats.yaml { };

  mkOidcProvider =
    {
      name,
      redirectUris,
      authorizationPolicy ? "one_factor",
      extraArgs ? { },
    }:
    {
      client_name = name;
      client_id = config.sops.placeholder."authelia/oidc/${name}/client_id";
      client_secret = config.sops.placeholder."authelia/oidc/${name}/client_secret_hashed";
      redirect_uris = redirectUris;
      authorization_policy = authorizationPolicy;
      consent_mode = "implicit";
    }
    // extraArgs;

in
{
  sops.templates."authelia/oidc-apps.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;

    file = yamlFormat.generate "authelia-oidc-apps-template.yaml" {
      identity_providers.oidc = {
        authorization_policies = {
          server_admins = {
            default_policy = "deny";
            rules = [
              {
                subject = "group:${shared.groups.ServerAdmins}";
                policy = "one_factor";
              }
            ];
          };

          media_admins = {
            default_policy = "deny";
            rules = [
              {
                subject = "group:${shared.groups.MediaAdmins}";
                policy = "one_factor";
              }
            ];
          };

        };

        clients = [
          (mkOidcProvider {
            name = "grist";
            redirectUris = [ "${networkingLib.mkUrl "grist"}/oauth2/callback" ];
          })
        ];
      };
    };
  };
}
