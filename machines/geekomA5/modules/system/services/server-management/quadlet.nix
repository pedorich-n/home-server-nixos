{ config, dockerLib, lib, ... }:
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
    containerConfig = rec {
      image = "portainer/portainer-ce:${containerVersions.portainer}";
      name = "portainer";
      networks = [ "traefik" ];
      environments = {
        TZ = "${config.time.timeZone}";
      };
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock:ro"
        # "/var/run/docker.sock:/var/run/docker.sock:ro"
        (storeFor "portainer" "/data")
      ];
      # user = userSetting;
      #TODO: make mkTraefikLabels return a list
      labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels { inherit name; port = 9000; });
    };

    serviceConfig = {
      Restart = "unless-stopped";
    };
  };
}
