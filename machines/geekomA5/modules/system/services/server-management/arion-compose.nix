{ config, dockerLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/server-management/${localPath}:${remotePath}";

  # userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";
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

      networks = dockerLib.externalTraefikNetwork;

      services = {
        homepage.service = rec {
          image = "ghcr.io/gethomepage/homepage:${containerVersions.homepage}";
          container_name = "homepage";
          networks = [ "traefik" ];
          restart = "unless-stopped";
          # user = userSetting;
          volumes = [
            # Managed by environment.mutable-files
            (storeFor "homepage/config" "/app/config")
            (storeFor "homepage/images" "/app/public/images")

            "/run/podman/podman.sock:/var/run/docker.sock:ro"
          ];
          labels = dockerLib.mkTraefikLabels {
            name = container_name;
            port = 3000;
            domain = config.custom.networking.domain;
          };
        };


        portainer.service = rec {
          image = "portainer/portainer-ce:${containerVersions.portainer}";
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
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; } //
            (dockerLib.mkHomepageLabels {
              name = "Portainer";
              group = "Server";
              weight = 10;
            });
        };
      };
    };
  };
}
