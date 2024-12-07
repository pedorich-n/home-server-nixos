{ config, containerLib, ... }:
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

  virtualisation.quadlet.containers.portainer = {
    requiresTraefikNetwork = true;
    wantsAuthentik = true;

    containerConfig = rec {
      image = "portainer/portainer-ce:${containerVersions.portainer}";
      name = "portainer";
      environments = {
        TZ = "${config.time.timeZone}";
      };
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock:ro"
        # "/var/run/docker.sock:/var/run/docker.sock:ro"
        (storeFor "portainer" "/data")
      ];
      # user = userSetting;
      labels = containerLib.mkTraefikLabels { inherit name; port = 9000; };
    };
  };
}
