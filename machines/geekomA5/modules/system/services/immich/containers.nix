{
  config,
  containerLib,
  systemdLib,
  networkingLib,
  lib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/immich";
  externalStoreRoot = "/mnt/external/immich-library";

  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    TZ = "${config.time.timeZone}";
    REDIS_HOSTNAME = "immich-valkey";
    DB_HOSTNAME = "immich-postgresql";

    IMMICH_TELEMETRY_INCLUDE = "all"; # See https://immich.app/docs/features/monitoring#prometheus
  };

  networks = [ "immich-internal.network" ];

  mkMappedVolumeForUserContainerRoot =
    localPath: remotePath:
    containerLib.mkIdmappedVolume {
      uidNamespace = 0;
      gidNamespace = 0;
      uidHost = config.users.users.user.uid;
      gidHost = config.users.groups.${config.users.users.user.group}.gid;
    } localPath remotePath;
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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/redis" "/data")
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
            # Looks like this container doesn't work properly with both `user` and `userns` set.
            # It spits "permission denied" errors when it tries to write to download ML models.
            # So I'll just leave it running as root inside the container for and map volume for root.
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/machine-learning/cache" "/cache")
          ];
          inherit networks;
          # inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.immich-valkey.ref
          containers.immich-postgresql.ref
        ];
      };

      immich-server = {
        requiresTraefikNetwork = true;
        wantsAuthelia = true;
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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/cache/thumbnails" "/data/thumbs")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/cache/profile" "/data/profile")
            (containerLib.mkMappedVolumeForUser externalStoreRoot "/data")
          ];
          labels =
            (containerLib.mkTraefikLabels {
              name = "immich-secure";
              port = 2283;
            })
            ++ (containerLib.mkTraefikMetricsLabels {
              name = "immich";
              domain = networkingLib.mkDomain "metrics";
              port = 8081;
              addPath = "/metrics";
            })
            ++ (containerLib.mkTraefikMetricsLabels {
              name = "immich-microservices";
              domain = networkingLib.mkDomain "metrics";
              port = 8082;
              addPath = "/metrics";
            });
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.immich-valkey.ref
            containers.immich-postgresql.ref
          ])
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };
    };

  };

}
