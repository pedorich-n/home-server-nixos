{ config, dockerLib, ... }:
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
    REDIS_HOSTNAME = "immich-redis";
    DB_HOSTNAME = "immich-postgresql";
    IMMICH_CONFIG_FILE = "/usr/src/app/custom-config.json";

    IMMICH_TELEMETRY_INCLUDE = "all"; # See https://immich.app/docs/features/monitoring#prometheus
  };
in
{
  systemd.services.arion-immich = {
    requires = [
      #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:62
      "zfs-mounted-external-immich.service"
      #LINK - machines/geekomA5/modules/system/services/immich/render-config.nix:20
      "immich-render-config.service"
    ];
  };

  virtualisation.arion.projects = {
    immich.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "immich") // dockerLib.externalTraefikNetwork;

      services = {
        redis.service = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
          container_name = "immich-redis";
          networks = [ "default" ];
          volumes = [
            (storeFor "redis" "/data")
          ];
          restart = "unless-stopped";
        };

        postgresql.service = {
          image = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          container_name = "immich-postgresql";
          environment = sharedEnvs;
          env_file = [ config.age.secrets.immich_compose_main.path ];
          networks = [ "default" ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/immich-app/immich-server:${containerVersions.immich-server}";
          container_name = "immich-server";
          networks = [
            "default"
            "traefik"
          ];
          environment = sharedEnvs;
          env_file = [ config.age.secrets.immich_compose_main.path ];
          depends_on = [
            "redis"
            "postgresql"
          ];
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          restart = "unless-stopped";
          volumes = immichVolumes;
          labels =
            (dockerLib.mkTraefikLabels { name = "immich"; port = 2283; }) //
            (dockerLib.mkTraefikMetricsLabels { name = "immich"; port = 8081; addPath = "/metrics"; }) //
            (dockerLib.mkTraefikMetricsLabels { name = "immich-microservices"; port = 8082; addPath = "/metrics"; });
        };

        machine-learning.service = {
          image = "ghcr.io/immich-app/immich-machine-learning:${containerVersions.immich-machine-learning}";
          container_name = "immich-machine-learning";
          networks = [ "default" ];
          restart = "unless-stopped";
          volumes = [
            (storeFor "cache/machine-learning" "/cache")
          ];
        };
      };
    };
  };

}
