{
  config,
  pkgs,
  networkingLib,
  ...
}:
let
  shared = import ../_shared.nix;

  yamlFormat = pkgs.formats.yaml { };

  defaultScopes = [
    "openid"
    "profile"
    "email"
    "groups"
  ];

  mkOidcProviderPrivate =
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
      public = false;
      authorization_policy = "one_factor";
      consent_mode = "implicit";
      scopes = defaultScopes;
    }
    // extraArgs;

  mkOidcProviderPublic =
    {
      name,
      id ? config.sops.placeholder."authelia/oidc/${name}/client_id",
      redirectUris,
      extraArgs ? { },
    }:
    {
      client_name = name;
      client_id = id;
      redirect_uris = redirectUris;
      public = true;
      authorization_policy = "one_factor";
      consent_mode = "implicit";
      require_pkce = true;
      pkce_challenge_method = "S256";
      scopes = defaultScopes;
      grant_types = [
        "authorization_code"
      ];
    }
    // extraArgs;

in
{
  sops.templates."authelia/oidc-apps.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
    restartUnits = [
      config.systemd.services.authelia-main.name
    ];

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
          role = {
            custom_claims = {
              role = {
                attribute = "admin_or_user";
              };
            };
          };

          roles = {
            custom_claims = {
              roles = {
                attribute = "admin_or_user_list";
              };
            };
          };

          userinfo_in_id_token = {
            # See https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter
            id_token = [
              "rat"
              "groups"
              "email"
              "email_verified"
              "alt_emails"
              "preferred_username"
              "name"
            ];
          };
        };

        scopes = {
          role = {
            claims = [ "role" ];
          };

          roles = {
            claims = [ "roles" ];
          };
        };

        cors = {
          allowed_origins_from_client_redirect_uris = true;
          endpoints = [
            "userinfo"
            "authorization"
            "token"
          ];
        };

        clients = [
          (mkOidcProviderPrivate {
            name = "audiobookshelf";
            redirectUris = [
              "${networkingLib.mkUrl "audiobookshelf"}/auth/openid/callback"
              "${networkingLib.mkUrl "audiobookshelf"}/auth/openid/mobile-redirect"
              "audiobookshelf://oauth"
              "lissen://oauth"
            ];
            extraArgs = {
              claims_policy = "roles";
              scopes = defaultScopes ++ [
                "roles"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "grist";
            redirectUris = [ "${networkingLib.mkUrl "grist"}/oauth2/callback" ];
          })

          (mkOidcProviderPrivate {
            name = "homeassistant";
            redirectUris = [ "${networkingLib.mkUrl "homeassistant"}/auth/oidc/callback" ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "immich";
            redirectUris = [
              "${networkingLib.mkUrl "immich"}/auth/login"
              "${networkingLib.mkUrl "immich"}/user-settings"
              "app.immich:///oauth-callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
              claims_policy = "role";
              scopes = defaultScopes ++ [
                "role"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "jellyfin";
            redirectUris = [
              "${networkingLib.mkUrl "jellyfin"}/sso/OID/redirect/Authelia"
              "${networkingLib.mkUrl "jellyfin"}/sso/OID/r/Authelia"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "librechat";
            redirectUris = [
              "${networkingLib.mkUrl "chat"}/oauth/openid/callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
              claims_policy = "roles";
              scopes = defaultScopes ++ [
                "roles"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "paperless";
            redirectUris = [ "${networkingLib.mkUrl "paperless"}/accounts/oidc/authelia/login/callback/" ];
          })

          (mkOidcProviderPrivate {
            name = "shelfmark";
            redirectUris = [ "${networkingLib.mkUrl "shelfmark"}/api/auth/oidc/callback" ];
          })

          (mkOidcProviderPrivate {
            name = "forgejo";
            redirectUris = [ "${networkingLib.mkUrl "git"}/user/oauth2/authelia/callback" ];
          })

          (mkOidcProviderPrivate {
            name = "gitea-mirror";
            redirectUris = [ "${networkingLib.mkUrl "gitea-mirror"}/api/auth/sso/callback/Authelia" ];
            extraArgs = {
              claims_policy = "userinfo_in_id_token";
            };
          })

          (mkOidcProviderPublic {
            name = "dashy";
            id = "dashy";
            redirectUris = [
              (networkingLib.mkUrl "dashy")
            ];
            extraArgs = {
              claims_policy = "roles";
              scopes = defaultScopes ++ [
                "roles"
              ];
            };
          })
        ];
      };
    };
  };
}
