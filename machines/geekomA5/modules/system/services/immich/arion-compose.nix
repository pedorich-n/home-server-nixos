{ config, dockerLib, ... }:
let
  immichVersion = "v1.102.3";

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
    ];


  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    REDIS_HOSTNAME = "immich-redis";
    DB_HOSTNAME = "immich-postgresql";

    IMMICH_METRICS = "true"; # See https://immich.app/docs/features/monitoring#prometheus
  };
in
{
  systemd.services.arion-immich = {
    #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:72
    requires = [ "zfs-mounted-external-immich.service" ];
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
          labels = {
            "wud.watch" = "false"; # Fetch the version from Immich's docker-compose file
          };
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
          labels = {
            "wud.watch" = "false"; # Fetch the version from Immich's docker-compose file
          };
        };

        server.service = {
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          container_name = "immich-server";
          command = [ "start.sh" "immich" ];
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
          restart = "unless-stopped";
          volumes = immichVolumes;
          labels = dockerLib.mkTraefikLabels { name = "immich"; port = 3001; } // {
            "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
            "wud.display.icon" = "si:immich";
          };
        };

        microservices.service = {
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          container_name = "immich-microservices";
          command = [ "start.sh" "microservices" ];
          networks = [
            "default"
            "traefik" # Only used to allow netdata to access metrics. This service isn't actually exposed via traefik
          ];
          environment = sharedEnvs;
          env_file = [ config.age.secrets.immich_compose_main.path ];
          volumes = immichVolumes;
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          depends_on = [
            "redis"
            "postgresql"
          ];
          restart = "unless-stopped";
          labels = {
            "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
            "wud.display.icon" = "si:immich";
          };
        };

        machine-learning.service = {
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
          container_name = "immich-machine-learning";
          networks = [ "default" ];
          restart = "unless-stopped";
          volumes = [
            (storeFor "cache/machine-learning" "/cache")
          ];
          labels = {
            "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
            "wud.display.icon" = "si:immich";
          };
        };
      };
    };
  };

}
