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

  systemd.services.copyparty.environment = {
    PRTY_NO_CFSSL = "1"; # Disable CFSSL certificate generation
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
      };

      volumes = {
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
      };

      services.copyparty-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.tcp.copyparty-web.portStr}"; } ];
      };
    };
  };
}
