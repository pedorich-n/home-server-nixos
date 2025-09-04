{
  config,
  networkingLib,
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

  serverAdminsApps = [
    "cockpit"
    "netdata"
    "traefik"
    "zigbee2mqtt"
  ];

  mediaAdminsApps = [
    "multiscrobbler"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "sabnzbd"
    "sonarr"
  ];

  regularApps = [
    "copyparty"
    "homeassistant"
    "jellyfin"
    "maloja"
  ];

  stateRoot = "/var/lib/authelia-main";
in
{
  custom.networking.ports.tcp.authelia-main = {
    port = 9091;
    openFirewall = false;
  };

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
      };

      settingsFiles = [
        config.sops.templates."authelia/oidc-apps.yaml".path
      ];

      environmentVariables = {
        X_AUTHELIA_CONFIG_FILTERS = "template";
      };

      settings = {
        theme = "auto";

        log = {
          format = "text";
        };

        server = {
          address = "tcp://127.0.0.1:${portsCfg.portStr}";
          endpoints.authz.forward-auth = {
            implementation = "ForwardAuth";
          };
        };

        authentication_backend = {
          file = {
            path = config.sops.templates."authelia/users.yaml".path;
            watch = false;
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
              apps = serverAdminsApps;
              group = shared.groups.ServerAdmins;
            })
            (mkAccessRule {
              apps = mediaAdminsApps;
              group = shared.groups.MediaAdmins;
            })
            (mkAccessRule { apps = regularApps; })
          ];
        };
      };
    };
  };
}
