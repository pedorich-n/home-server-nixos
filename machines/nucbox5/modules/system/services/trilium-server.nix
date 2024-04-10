{ pkgs-unstable, ... }:
let
  port = 52000;
in
{
  custom = {
    networking.ports.tcp."trilium-main".port = port;

    services.trilium-server = {
      enable = true;
      package = pkgs-unstable.trilium-server;
      nginx.enable = false;

      dataDir = "/mnt/store/trilium/main";
      settings = {
        # Based on https://github.com/zadam/trilium/blob/bfb8aa64816da24b6eca0a790d1eb3d9874ec279/config-sample.ini
        General = {
          instanceName = "Trilium Main";
          noAuthentication = false;
          noBackup = false;
          noDesktopIcon = true;
        };

        Network = {
          host = "127.0.0.1";
          inherit port;
          htpps = false;
          trustedReverseProxy = "loopback";
        };
      };
    };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers.trilium = {
        entryPoints = [ "web" ];
        rule = "Host(`trilium.server.local`)";
        service = "trilium";
      };

      services.trilium.loadBalancer.servers = [{ url = "http://localhost:${toString port}"; }];
    };
  };
}
