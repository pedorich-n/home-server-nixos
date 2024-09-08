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
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; };
        };
      };
    };
  };
}
