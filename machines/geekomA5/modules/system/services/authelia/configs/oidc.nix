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
      extraArgs ? { },
    }:
    {
      client_name = name;
      client_id = config.sops.placeholder."authelia/oidc/${name}/client_id";
      client_secret = config.sops.placeholder."authelia/oidc/${name}/client_secret_hashed";
      redirect_uris = redirectUris;
      authorization_policy = "one_factor";
      consent_mode = "implicit";
    }
    // extraArgs;

in
{
  sops.templates."authelia/oidc-apps.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;

    file = yamlFormat.generate "authelia-oidc-apps-template.yaml" {
      definitions.user_attributes = {
        admin_or_user = {
          expression = ''"${shared.groups.Admins}" in groups ? "admin" : "user"'';
        };

        admin_or_user_list = {
          expression = ''"${shared.groups.Admins}" in groups ? ["admin"] : ["user"]'';
        };
      };

      identity_providers.oidc = {
        claims_policies = {
          abs_role = {
            custom_claims = {
              absgroups = {
                attribute = "admin_or_user_list";
              };
            };
          };

          immich_role = {
            custom_claims = {
              immich_role = {
                attribute = "admin_or_user";
              };
            };
          };
        };

        scopes = {
          absgroups = {
            claims = [ "absgroups" ];
          };

          immich_role = {
            claims = [ "immich_role" ];
          };
        };

        clients = [
          (mkOidcProvider {
            name = "audiobookshelf";
            redirectUris = [
              "${networkingLib.mkUrl "audiobookshelf"}/auth/openid/callback"
              "${networkingLib.mkUrl "audiobookshelf"}/auth/openid/mobile-redirect"
              "audiobookshelf://oauth"
            ];
            extraArgs = {
              claims_policy = "abs_role";
              scopes = [
                "openid"
                "profile"
                "email"
                "absgroups"
              ];
            };
          })
          (mkOidcProvider {
            name = "grist";
            redirectUris = [ "${networkingLib.mkUrl "grist"}/oauth2/callback" ];
          })
          (mkOidcProvider {
            name = "immich";
            redirectUris = [
              "${networkingLib.mkUrl "immich"}/auth/login"
              "${networkingLib.mkUrl "immich"}/user-settings"
              "app.immich:///oauth-callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
              claims_policy = "immich_role";
              scopes = [
                "openid"
                "profile"
                "email"
                "immich_role"
              ];
            };
          })
          (mkOidcProvider {
            name = "paperless";
            redirectUris = [ "${networkingLib.mkUrl "paperless"}/accounts/oidc/authelia/login/callback/" ];
          })
        ];
      };
    };
  };
}
