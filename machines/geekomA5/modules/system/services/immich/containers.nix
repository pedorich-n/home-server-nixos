{ config, containerLib, systemdLib, networkingLib, ... }:
let
  storeRoot = "/mnt/store/immich";
  externalStoreRoot = "/mnt/external/immich-library";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    TZ = "${config.time.timeZone}";
    REDIS_HOSTNAME = "immich-valkey";
    DB_HOSTNAME = "immich-postgresql";

    IMMICH_TELEMETRY_INCLUDE = "all"; # See https://immich.app/docs/features/monitoring#prometheus
  };

  networks = [ "immich-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "immich";

    containers = {
      immich-postgresql = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = sharedEnvs;
          environmentFiles = [ config.sops.secrets."immich/postgresql.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      immich-valkey = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          volumes = [
            (mappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      immich-machine-learning = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          volumes = [
            (mappedVolumeForUser "${storeRoot}/cache/machine-learning" "/cache")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          "immich-valkey.service"
          "immich-postgresql.service"
        ];
      };

      immich-server = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = sharedEnvs;
          environmentFiles = [ config.sops.secrets."immich/main.env".path ];
          addGroups = [
            (builtins.toString config.users.groups.render.gid) # For HW Transcoding
          ];
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            (mappedVolumeForUser "${storeRoot}/cache/thumbnails" "/usr/src/app/upload/thumbs")
            (mappedVolumeForUser "${storeRoot}/cache/profile" "/usr/src/app/upload/profile")
            (mappedVolumeForUser externalStoreRoot "/usr/src/app/upload")
          ];
          labels =
            (containerLib.mkTraefikLabels {
              name = "immich-secure";
              port = 2283;
            }) ++
            (containerLib.mkTraefikMetricsLabels {
              name = "immich";
              domain = networkingLib.mkDomain "metrics";
              port = 8081;
              addPath = "/metrics";
            }) ++
            (containerLib.mkTraefikMetricsLabels {
              name = "immich-microservices";
              domain = networkingLib.mkDomain "metrics";
              port = 8082;
              addPath = "/metrics";
            });
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          "immich-valkey.service"
          "immich-postgresql.service"
        ];
      };
    };

  };

}
