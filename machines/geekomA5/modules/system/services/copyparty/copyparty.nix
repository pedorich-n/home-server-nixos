{
  config,
  pkgs-unstable,
  networkingLib,
  ...
}:
let
  root = "/mnt/external/data-library";

  portsCfg = config.custom.networking.ports;
in
{
  custom.networking.ports.tcp = {
    copyparty-web = {
      port = 46000;
      openFirewall = false;
    };
  };

  systemd = {
    services.copyparty.environment = {
      PRTY_NO_TLS = "true"; # Disable CFSSL certificate generation
    };

    tmpfiles.settings."90-copyparty-history" = {
      "/var/lib/copyparty/history" = {
        "d" = {
          mode = "0755";
          user = config.users.users.copyparty.name;
          group = config.users.users.copyparty.group;
        };
      };
    };
  };

  services = {
    copyparty = {
      enable = true;
      package = pkgs-unstable.copyparty.override {
        withZeroMQ = false;
        withFTP = false;
      };

      settings = {
        i = "127.0.0.1"; # Interface to bind to
        p = portsCfg.tcp.copyparty-web.portStr; # Port to listen on

        rproxy = "1"; # Enable reverse proxy mode

        idp-h-usr = "X-authentik-username";
        idp-h-grp = "X-authentik-groups";

        hist = "/var/lib/copyparty/history";
      };

      volumes = {
        "/" = {
          path = root;
          access = {
            "r" = "*";
          };
        };

        "/media" = {
          path = "${root}/media";
          access = {
            "r" = "*";
          };
        };

        "/downloads" = {
          path = "${root}/downloads";
          access = {
            "r" = "*";
          };
        };

        "/share" = {
          path = "${root}/share";
          access = {
            "r" = "*";
            "w" = "*";
          };
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.copyparty-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "copyparty"}`)";
        service = "copyparty-secure";
        middlewares = [ "authentik-secure@docker" ];
      };

      services.copyparty-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.copyparty-web.portStr}"; } ];
      };
    };
  };
}
