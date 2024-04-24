{ dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/immich/${localPath}:${remotePath}";

  cacheVolumes = [
    (storeFor "cache/thumbnails" "/usr/src/app/upload/thumbs")
    (storeFor "cache/profile" "/usr/src/app/upload/profile")
  ];

  vars = {
    immichVersion = "v1.102.3";
    uploadLocation = ""; # TODO
  };

  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    REDIS_HOSTNAME = "immich-redis";
    DB_HOSTNAME = "immich-postgresql";

    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";

    # IMMICH_METRICS = true; # TODO see https://immich.app/docs/features/monitoring#prometheus
  };
in
{
  virtualisation.arion.projects = {
    immich.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "immich") // dockerLib.externalTraefikNetwork;

      services = {
        redis.service = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
          container_name = "immich-redis";
          networks = [ "default" ];
          restart = "unless-stopped";
        };

        postgresql.service = {
          image = "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          container_name = "immich-postgresql";
          environment = sharedEnvs // {
            POSTGRES_PASSWORD = "\${DB_PASSWORD}"; # TODO
            POSTGRES_USER = "\${DB_USERNAME}";
            POSTGRES_DB = "\${DB_DATABASE_NAME}";
          };
          networks = [ "default" ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
        };

        server.service = rec{
          image = "ghcr.io/immich-app/immich-server:${vars.immichVersion}";
          container_name = "immich-server";
          command = [ "start.sh" "immich" ];
          networks = [
            "default"
            "traefik"
          ];
          environment = sharedEnvs // { }; # TODO
          env_file = [ ]; # TODO
          depends_on = [
            "redis"
            "postgresql"
          ];
          restart = "unless-stopped";
          volumes = cacheVolumes ++ [
            "${vars.uploadLocation}:/user/src/app/upload"
            "/etc/localtime:/etc/localtime:ro"
          ];
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 2283; } // {
            # "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?''; # TODO: enable WUD
          };
        };

        microservices.service = {
          image = "ghcr.io/immich-app/immich-server:${vars.immichVersion}";
          container_name = "immich-microservices";
          command = [ "start.sh" "microservices" ];
          networks = [ "default" ];
          environment = sharedEnvs // { }; # TODO
          env_file = [ ]; # TODO
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          depends_on = [
            "redis"
            "postgresql"
          ];
          restart = "unless-stopped";
          volumes = cacheVolumes ++ [
            "${vars.uploadLocation}:/user/src/app/upload"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        machine-learning.service = {
          image = "ghcr.io/immich-app/immich-machine-learning:${vars.immichVersion}";
          container_name = "immich-machine-learning";
          networks = [ "default" ];
          environment = sharedEnvs // { }; # TODO
          env_file = [ ]; # TODO
          restart = "unless-stopped";
          volumes = [
            (storeFor "cache/machine-learning" "/cache")
          ];
        };
      };
    };
  };

}
