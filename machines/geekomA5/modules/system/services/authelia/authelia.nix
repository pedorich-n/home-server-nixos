{
  config,
  networkingLib,
  systemdLib,
  lib,
  ...
}:
let
  shared = import ./_shared.nix;

  portsCfg = config.custom.networking.ports.tcp.authelia-main;

  mkAccessRule =
    {
      apps,
      group ? null,
    }:
    {
      domain = lib.map networkingLib.mkDomain apps;
      policy = "one_factor";
    }
    // (lib.optionalAttrs (group != null) {
      subject = "group:${group}";
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
    "zigbee2mqtt"
  ];

  regularApps = [
    "copyparty"
    "homeassistant"
    "maloja"
  ];

  stateRoot = "/var/lib/authelia-main";
in
{
  custom.networking.ports.tcp.authelia-main = {
    port = 9091;
    openFirewall = false;
  };

  systemd.services.authelia-main = {
    unitConfig = systemdLib.requiresAfter [ "redis-authelia.service" ];
  };

  users.users.authelia-main.extraGroups = [ config.services.redis.servers.authelia.group ];

  services = {
    traefik.dynamicConfigOptions.http = {
      middlewares.authelia = {
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

        notifier = {
          disable_startup_check = false;
          filesystem.filename = "${stateRoot}/notifier.log";
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
              group = shared.groups.Admins;
            })
            (mkAccessRule { apps = regularApps; })
          ];
        };
      };
    };
  };
}
