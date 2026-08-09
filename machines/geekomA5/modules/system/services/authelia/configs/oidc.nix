{
  config,
  pkgs,
  autheliaLib,
  networkingLib,
  ...
}:
let

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

    file = pkgs.writers.writeYAML "authelia-oidc-apps-template.yaml" {
      definitions.user_attributes = {
        admin_or_user = {
          expression = ''"${autheliaLib.groups.Admins}" in groups ? "admin" : "user"'';
        };

        admin_or_user_list = {
          expression = ''"${autheliaLib.groups.Admins}" in groups ? ["admin"] : ["user"]'';
        };

        groups_concatenated = {
          expression = ''groups.join(",")'';
        };
      };

      identity_providers.oidc = {
        #LINK - https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/
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

          groups_concatenated = {
            custom_claims = {
              groups_concatenated = {
                attribute = "groups_concatenated";
              };
            };
          };

          # Getting the value from LDAP
          #LINK - machines/geekomA5/modules/system/services/authelia/configs/ldap.nix:36
          ssh_public_key = {
            custom_claims = {
              ssh_public_key = { };
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

          dashy = {
            # See https://www.authelia.com/integration/openid-connect/clients/dashy/#configuration-escape-hatch
            id_token = [
              "groups"
              "email"
              "email_verified"
              "alt_emails"
              "preferred_username"
              "name"
            ];

            custom_claims = {
              roles = {
                attribute = "admin_or_user_list";
              };
            };
          };
        };

        scopes = {
          role = {
            claims = [ "role" ];
          };

          roles = {
            claims = [ "roles" ];
          };

          groups_concatenated = {
            claims = [ "groups_concatenated" ];
          };

          ssh_public_key = {
            claims = [ "ssh_public_key" ];
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
              "${networkingLib.mkLocalUrl "audiobookshelf"}/auth/openid/callback"
              "${networkingLib.mkLocalUrl "audiobookshelf"}/auth/openid/mobile-redirect"
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
            redirectUris = [
              "${networkingLib.mkLocalUrl "grist"}/oauth2/callback"
            ];
          })

          (mkOidcProviderPrivate {
            name = "homeassistant";
            redirectUris = [
              "${networkingLib.mkLocalUrl "homeassistant"}/auth/oidc/callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "immich";
            redirectUris = [
              "${networkingLib.mkLocalUrl "immich"}/auth/login"
              "${networkingLib.mkLocalUrl "immich"}/user-settings"
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
            name = "librechat";
            redirectUris = [
              "${networkingLib.mkLocalUrl "chat"}/oauth/openid/callback"
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
            redirectUris = [
              "${networkingLib.mkLocalUrl "paperless"}/accounts/oidc/authelia/login/callback/"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "shelfmark";
            redirectUris = [
              "${networkingLib.mkLocalUrl "shelfmark"}/api/auth/oidc/callback"
            ];
          })

          (mkOidcProviderPrivate {
            name = "forgejo";
            redirectUris = [
              "${networkingLib.mkLocalUrl "git"}/user/oauth2/authelia/callback"
            ];
            extraArgs = {
              claims_policy = "ssh_public_key";
              scopes = defaultScopes ++ [
                "ssh_public_key"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "gitea-mirror";
            redirectUris = [
              "${networkingLib.mkLocalUrl "gitea-mirror"}/api/auth/sso/callback/Authelia"
            ];
            extraArgs = {
              claims_policy = "userinfo_in_id_token";
            };
          })

          (mkOidcProviderPublic {
            name = "dashy";
            id = "dashy";
            redirectUris = [
              (networkingLib.mkLocalUrl "dashy")
            ];
            extraArgs = {
              claims_policy = "dashy";
              scopes = defaultScopes ++ [
                "roles"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "trek";
            redirectUris = [
              "${networkingLib.mkLocalUrl "trek"}/api/auth/oidc/callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "olivetin";
            redirectUris = [
              "${networkingLib.mkLocalUrl "olivetin"}/oauth/callback"
            ];
            extraArgs = {
              claims_policy = "groups_concatenated";
              scopes = defaultScopes ++ [
                "groups_concatenated"
              ];
            };
          })

          (mkOidcProviderPrivate {
            name = "airtrail";
            redirectUris = [
              "${networkingLib.mkLocalUrl "airtrail"}/login"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "safebucket";
            redirectUris = [
              "${networkingLib.mkUrl "safebucket"}/api/v1/auth/providers/authelia/callback"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })

          (mkOidcProviderPrivate {
            name = "papra";
            redirectUris = [
              "${networkingLib.mkLocalUrl "papra"}/api/auth/oauth2/callback/authelia"
            ];
            extraArgs = {
              token_endpoint_auth_method = "client_secret_post";
            };
          })
        ];
      };
    };
  };
}
