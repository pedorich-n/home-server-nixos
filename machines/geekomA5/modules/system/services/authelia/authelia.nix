{
  config,
  networkingLib,
  systemdLib,
  lib,
  pkgs-unstable,
  ...
}:
let
  shared = import ./_shared.nix;

  portsCfg = config.custom.networking.ports.tcp.authelia-main;

  mkAccessRule =
    {
      apps,
      groups ? [ ],
    }:
    {
      domain = lib.map networkingLib.mkDomain apps;
      policy = "one_factor";
    }
    // (lib.optionalAttrs (groups != [ ]) {
      # Subject can be either a single item or a list of items
      subject = lib.map (group: if (lib.isList group) then (lib.map (g: "group:${g}") group) else "group:${group}") groups;
    });

  adminApps = [
    "cockpit"
    "multiscrobbler"
    "netdata"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "sabnzbd"
    "sonarr"
    "traefik"
    "shelfmark"
    "zigbee2mqtt"
  ];

  regularApps = [
    "audiobookshelf"
    "dashy"
    "forgejo"
    "gitea-mirror"
    "grist"
    "homeassistant"
    "immich"
    "jellyfin"
    "librechat"
    "maloja"
    "paperless"
    "shelfmark"
  ];

  serviceApps = [
    "copyparty"
  ];

  stateRoot = "/var/lib/authelia-main";
in
{
  custom.networking.ports.tcp.authelia-main = {
    port = 9091;
    openFirewall = false;
  };

  systemd.services.authelia-main = {
    unitConfig = systemdLib.requiresAfter [
      config.systemd.services.redis-authelia.name
      config.systemd.services.lldap.name
    ];

    serviceConfig = {
      SupplementaryGroups = [
        config.services.redis.servers.authelia.group
      ];
    };
  };

  services = {
    traefik.dynamicConfigOptions.http = {
      middlewares = {
        authelia = {
          forwardAuth = {
            address = "http://127.0.0.1:${portsCfg.portStr}/api/authz/forward-auth";
            trustForwardHeader = true;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ];
          };
        };

        authelia-basic = {
          forwardAuth = {
            address = "http://127.0.0.1:${portsCfg.portStr}/api/authz/forward-auth-basic";
            trustForwardHeader = true;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ];
          };
        };
      };

      routers.authelia-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "authelia"}`)";
        service = "authelia-secure";
      };

      services.authelia-secure = {
        loadBalancer.servers = [ { url = "http://127.0.0.1:${portsCfg.portStr}"; } ];
      };
    };

    authelia.instances.main = {
      enable = true;
      package = pkgs-unstable.authelia;

      secrets = {
        jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
        storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
        oidcHmacSecretFile = config.sops.secrets."authelia/oidc/hmac_secret".path;
        oidcIssuerPrivateKeyFile = config.sops.secrets."authelia/oidc/jwks.key".path;
        sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
      };

      settingsFiles = [
        config.sops.templates."authelia/oidc-apps.yaml".path
        config.sops.templates."authelia/ldap.yaml".path
        config.sops.templates."authelia/smtp.yaml".path
      ];

      environmentVariables = {
        X_AUTHELIA_CONFIG_FILTERS = "template";
        AUTHELIA_SESSION_REDIS_PASSWORD_FILE = config.sops.secrets."authelia/redis/password".path;
      };

      settings = {
        theme = "auto";

        log = {
          level = "info";
          format = "text";
        };

        server = {
          address = "tcp://127.0.0.1:${portsCfg.portStr}";
          endpoints.authz = {
            forward-auth = {
              implementation = "ForwardAuth";
            };
            forward-auth-basic = {
              implementation = "ForwardAuth";
              authn_strategies = [
                {
                  name = "HeaderAuthorization";
                  schemes = [ "Basic" ];
                }
                { name = "CookieSession"; }
              ];
            };
          };
        };

        webauthn = {
          disable = false;
          enable_passkey_login = true;

          selection_criteria = {
            discoverability = "preferred";
          };
        };

        storage = {
          local.path = "${stateRoot}/db.sqlite3";
        };

        session = {
          redis = {
            host = config.services.redis.servers.authelia.unixSocket;
          };

          name = "authelia_session";
          same_site = "lax";
          inactivity = "1w";
          expiration = "1h";
          remember_me = "1M";
          cookies = [
            {
              domain = config.custom.networking.domain;
              authelia_url = networkingLib.mkUrl "authelia";
              inactivity = "1M";
              expiration = "24h";
              remember_me = "6M";
            }
          ];
        };

        access_control = {
          default_policy = "deny";
          rules = [
            (mkAccessRule {
              apps = adminApps;
              groups = [ shared.groups.Admins ];
            })
            (mkAccessRule {
              apps = regularApps;
              groups = [ shared.groups.Users ];
            })
            (mkAccessRule {
              apps = serviceApps;
              groups = [
                shared.groups.Users
                shared.groups.Service
              ];
            })
          ];
        };
      };
    };
  };
}
