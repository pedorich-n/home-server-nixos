{
  config,
  autheliaLib,
  networkingLib,
  systemdLib,
  lib,
  pkgs-unstable,
  ...
}:
let
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
    "multiscrobbler"
    "netdata"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "sabnzbd"
    "sabnzbd-old"
    "sonarr"
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
    "librechat"
    "maloja"
    "paperless"
    "shelfmark"
  ];

  serviceApps = [
    "copyparty"
  ];

  stateRoot = "/var/lib/authelia-main";

  socketPath = "/run/authelia-main/authelia.sock";
in
{
  custom.services.caddy.hosts.authelia = {
    upstream = "unix/${socketPath}";
  };

  systemd.services = {
    caddy.serviceConfig.SupplementaryGroups = [
      config.services.authelia.instances.main.group
    ];

    authelia-main = {
      unitConfig = systemdLib.requiresAfter [
        config.systemd.services.redis-authelia.name
        config.systemd.services.lldap.name
      ];

      serviceConfig = {
        RuntimeDirectory = "authelia-main";
        RuntimeDirectoryMode = "0750";
        SupplementaryGroups = [
          config.services.redis.servers.authelia.group
        ];
      };
    };
  };

  services = {
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
          address = "unix://${socketPath}?umask=0117"; # 660 permissions

          #LINK - https://www.authelia.com/configuration/miscellaneous/server-endpoints-authz/
          endpoints.authz = {
            forward-auth = {
              implementation = "ForwardAuth";
              # LINK - https://www.authelia.com/reference/guides/proxy-authorization/#authn-strategies
              authn_strategies = [
                { name = "CookieSession"; }
              ];
            };
            forward-auth-basic = {
              implementation = "ForwardAuth";
              # LINK - https://www.authelia.com/reference/guides/proxy-authorization/#authn-strategies
              authn_strategies = [
                {
                  name = "HeaderAuthorization";
                  schemes = [ "Basic" ];
                  scheme_basic_cache_lifespan = "5m";
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
              groups = [ autheliaLib.groups.Admins ];
            })
            (mkAccessRule {
              apps = regularApps;
              groups = [ autheliaLib.groups.Users ];
            })
            (mkAccessRule {
              apps = serviceApps;
              groups = [
                autheliaLib.groups.Users
                autheliaLib.groups.Service
              ];
            })
          ];
        };
      };
    };
  };
}
