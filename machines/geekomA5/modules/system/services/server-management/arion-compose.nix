{ config, dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/server-management/${localPath}:${remotePath}";
in
{

  networking.firewall.interfaces."podman+" = {
    allowedTCPPorts = [
      config.custom.networking.ports.tcp.traefik-metrics.port # Metrics
    ];
  };

  virtualisation.arion.projects = {
    server-management.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "server-management") // dockerLib.externalTraefikNetwork;

      services = {
        portainer.service = rec {
          image = "portainer/portainer-ce:2.20.1-alpine";
          container_name = "portainer";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
            # "/var/run/docker.sock:/var/run/docker.sock:ro"
            (storeFor "portainer" "/data")
          ];
          networks = [ "traefik" ];
          # user = userSetting;
          restart = "unless-stopped";
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; } // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?-alpine$'';
            "wud.display.icon" = "si:portainer";
          };
        };

        whatsupdocker.service = rec {
          image = "fmartinou/whats-up-docker:6.3.0";
          container_name = "whatsupdocker";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          networks = [ "traefik" ];
          restart = "unless-stopped";
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
            (storeFor "whatsupdocker" "/store")
          ];
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 3000; } // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
          };
        };
      };
    };
  };
}
