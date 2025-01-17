{ config, containerLib, systemdLib, ... }:
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
    REDIS_HOSTNAME = "immich-redis";
    DB_HOSTNAME = "immich-vectordb";
    IMMICH_CONFIG_FILE = "/usr/src/app/custom-config.json";

    IMMICH_TELEMETRY_INCLUDE = "all"; # See https://immich.app/docs/features/monitoring#prometheus
  };

  networks = [ "immich-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "immich";

    containers = {
      immich-vectordb = {
        usernsAuto.enable = true;

        containerConfig = {
          image = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          environments = sharedEnvs;
          environmentFiles = [ config.sops.secrets."immich/postgresql".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      immich-redis = {
        usernsAuto.enable = true;

        containerConfig = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
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

        unitConfig = systemdLib.requiresAfter
          [
            "immich-redis.service"
            "immich-vectordb.service"
          ]
          { };
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
          environmentFiles = [ config.sops.secrets."immich/main".path ];
          addGroups = [
            (builtins.toString config.users.groups.render.gid) # For HW Transcoding
          ];
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${config.custom.services.immich.configPath}:/usr/src/app/custom-config.json:ro"
            (mappedVolumeForUser "${storeRoot}/cache/thumbnails" "/usr/src/app/upload/thumbs")
            (mappedVolumeForUser "${storeRoot}/cache/profile" "/usr/src/app/upload/profile")
            (mappedVolumeForUser externalStoreRoot "/usr/src/app/upload")
          ];
          labels =
            (containerLib.mkTraefikLabels { name = "immich"; port = 2283; }) ++
            (containerLib.mkTraefikMetricsLabels { name = "immich"; port = 8081; addPath = "/metrics"; }) ++
            (containerLib.mkTraefikMetricsLabels { name = "immich-microservices"; port = 8082; addPath = "/metrics"; });
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "immich-redis.service"
            "immich-vectordb.service"
            #LINK - machines/geekomA5/modules/system/services/immich/render-config-runtime.nix:20
            "immich-render-config.service"
          ]
          { };
      };
    };

  };

}
