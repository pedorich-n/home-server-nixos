{ config, dockerLib, lib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/paperless/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: "/mnt/external/paperless-library/${localPath}:${remotePath}";
in
{
  systemd.targets.paperless = {
    wants = [
      "paperless-redis.service"
      "paperless-postgresql.service"
      "paperless.service"
    ];
  };


  virtualisation.quadlet = {
    networks = {
      paperless-internal.networkConfig.name = "paperless-internal";
    };

    containers = {
      paperless-redis = {
        containerConfig = {
          image = "docker.io/library/redis:${containerVersions.paperless-redis}";
          name = "paperless-redis";
          networks = [ "paperless-internal" ];
          volumes = [
            (storeFor "redis" "/data")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };
      };

      paperless-postgresql = {
        containerConfig = {
          image = "docker.io/library/postgres:${containerVersions.paperless-postgresql}";
          name = "paperless-postgresql";
          environmentFiles = [ config.age.secrets.paperless.path ];
          networks = [ "paperless-internal" ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };
      };

      paperless = {
        containerConfig = {
          image = "ghcr.io/paperless-ngx/paperless-ngx:${containerVersions.paperless}";
          name = "paperless";
          networks = [
            "paperless-internal"
            "traefik"
          ];
          environments = {
            PAPERLESS_DBHOST = "paperless-postgresql";
            PAPERLESS_DBENGINE = "postgres";
            PAPERLESS_REDIS = "redis://paperless-redis:6379";

            PAPERLESS_TRASH_DIR = "/usr/src/paperless/media/trash";

            PAPERLESS_OCR_LANGUAGES = ''"eng jpn jpn-vert ukr rus"''; # Confusingly this only installs the language packs
            PAPERLESS_OCR_LANGUAGE = "ukr+rus+eng+jpn+jpn_vert"; # And this hints the OCR engine which languages to try to detect

            PAPERLESS_SOCIAL_AUTO_SIGNUP = "true";
            PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http";
            PAPERLESS_URL = "http://paperless.${config.custom.networking.domain}";
          };
          environmentFiles = [ config.age.secrets.paperless.path ];
          volumes = [
            (storeFor "data" "/usr/src/paperless/data")
            (storeFor "export" "/usr/src/paperless/export")
            (externalStoreFor "media" "/usr/src/paperless/media")
            (externalStoreFor "media/trash" "/usr/src/paperless/media/trash")
          ];
          #TODO: make mkTraefikLabels return a list
          labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels { name = "paperless"; port = 8000; });
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          Requires = [
            "paperless-redis.service"
            "paperless-postgresql.service"
            #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:72
            "zfs-mounted-external-paperless.service"
          ];
          # TODO: fix service name
          # After = [ "arion-authentik.service" ];
        };
      };
    };
  };

}
