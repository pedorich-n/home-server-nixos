{
  config,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.authelia-main;

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
            path = ./users.yaml;
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
            {
              domain = networkingLib.mkDomain "*";
              policy = "one_factor";
            }
          ];
        };
      };
    };
  };
}
