{ config, dockerLib, lib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/immich/${localPath}:${remotePath}";

  cacheVolumes = [
    (storeFor "cache/thumbnails" "/usr/src/app/upload/thumbs")
    (storeFor "cache/profile" "/usr/src/app/upload/profile")
  ];

  uploadVolumes = [
    "/mnt/external/immich-library:/usr/src/app/upload"
  ];

  immichVolumes =
    cacheVolumes ++
    uploadVolumes ++
    [
      "/etc/localtime:/etc/localtime:ro"
      "${config.custom.services.immich.configPath}:/usr/src/app/custom-config.json"
    ];


  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    TZ = "${config.time.timeZone}";
    REDIS_HOSTNAME = "immich-redis";
    DB_HOSTNAME = "immich-vectordb";
    IMMICH_CONFIG_FILE = "/usr/src/app/custom-config.json";

    IMMICH_TELEMETRY_INCLUDE = "all"; # See https://immich.app/docs/features/monitoring#prometheus
  };
in
{
  systemd.targets.immich = {
    wants = [
      "immich-redis.service"
      "immich-vectordb.service"
      "immich-machine-learning.service"
      "immich-server.service"
    ];
  };

  virtualisation.quadlet = {
    networks = {
      immich-internal.networkConfig.name = "immich-internal";
    };

    containers = {
      immich-vectordb = {
        containerConfig = {
          image = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          name = "immich-vectordb";
          environments = sharedEnvs;
          environmentFiles = [ config.age.secrets.immich.path ];
          networks = [ "immich-internal" ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };
      };

      immich-redis = {
        containerConfig = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
          name = "immich-redis";
          networks = [ "immich-internal" ];
          volumes = [
            (storeFor "redis" "/data")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };
      };

      immich-machine-learning = {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:${containerVersions.immich-machine-learning}";
          name = "immich-machine-learning";
          networks = [ "immich-internal" ];
          volumes = [
            (storeFor "cache/machine-learning" "/cache")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "immich-redis.service"
            "immich-vectordb.service"
          ];
        };
      };

      immich-server = {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:${containerVersions.immich-server}";
          name = "immich-server";
          networks = [
            "immich-internal"
            "traefik"
          ];
          environments = sharedEnvs;
          environmentFiles = [ config.age.secrets.immich.path ];
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          volumes = immichVolumes;
          labels = lib.mapAttrsToList (name: value: "${name}=${value}") (
            (dockerLib.mkTraefikLabels { name = "immich"; port = 2283; }) //
            (dockerLib.mkTraefikMetricsLabels { name = "immich"; port = 8081; addPath = "/metrics"; }) //
            (dockerLib.mkTraefikMetricsLabels { name = "immich-microservices"; port = 8082; addPath = "/metrics"; })
          );
        };

        unitConfig = {
          Requires = [
            "immich-redis.service"
            "immich-vectordb.service"
            #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:62
            "zfs-mounted-external-immich.service"
            #LINK - machines/geekomA5/modules/system/services/immich/render-config.nix:20
            "immich-render-config.service"
          ];
        };
      };
    };

  };

}
