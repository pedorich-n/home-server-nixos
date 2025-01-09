{ config, containerLib, systemdLib, ... }:
let
  storeRoot = "/mnt/store/immich";
  externalStoreRoot = "/mnt/external/immich-library";

  containerIds = {
    uid = 1100;
    gid = 1100;
  };

  user = "${builtins.toString containerIds.uid}:${builtins.toString containerIds.gid}";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidNamespace = containerIds.uid;
        uidHost = config.users.users.user.uid;
        uidCount = 1;
        uidRelative = true;
        gidNamespace = containerIds.gid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
        gidCount = 1;
        gidRelative = true;
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
        usernsAuto = true;

        containerConfig = {
          image = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          environments = sharedEnvs;
          environmentFiles = [ config.age.secrets.immich.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks user;
        };
      };

      immich-redis = {
        usernsAuto = true;

        containerConfig = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
          volumes = [
            (mappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks user;
        };
      };

      immich-machine-learning = {
        useGlobalContainers = true;

        containerConfig = {
          volumes = [
            (mappedVolumeForUser "${storeRoot}/cache/machine-learning" "/cache")
          ];
          userns = "auto:size=65535";
          inherit networks user;
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

        containerConfig = {
          environments = sharedEnvs;
          environmentFiles = [ config.age.secrets.immich.path ];
          addGroups = [
            (builtins.toString config.users.groups.render.gid) # For HW Transcoding
          ];
          userns = "auto:size=65535";
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
          inherit networks user;
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
