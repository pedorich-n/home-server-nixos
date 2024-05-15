{ config, dockerLib, ... }:
let

  storeFor = localPath: remotePath: "/mnt/store/paperless/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: "/mnt/external/paperless-library/${localPath}:${remotePath}";
in
{
  systemd.services.arion-immich = {
    requires = [
      #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:72
      "zfs-mounted-external-paperless.service"
    ];
  };

  virtualisation.arion.projects = {
    paperless.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "paperless") // dockerLib.externalTraefikNetwork;

      services = {
        redis.service = {
          image = "redis:7.2.4";
          container_name = "paperless-redis";
          networks = [ "default" ];
          volumes = [
            (storeFor "redis" "/data")
          ];
          restart = "unless-stopped";
          labels = {
            "wud.watch" = "false"; # Fetch the version from Paperless' docker-compose file
          };
        };

        postgresql.service = {
          image = "postgres:16.3-alpine3.18";
          container_name = "paperless-postgresql";
          env_file = [ config.age.secrets.paperless_compose.path ];
          networks = [ "default" ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
          labels = {
            "wud.watch" = "false"; # Fetch the version from Paperless' docker-compose file
          };
        };

        server.service = {
          image = "ghcr.io/paperless-ngx/paperless-ngx:2.8.4";
          container_name = "paperless-server";
          networks = [
            "default"
            "traefik"
          ];
          environment = {
            PAPERLESS_DBHOST = "postgresql";
            PAPERLESS_DBENGINE = "postgres";
            PAPERLESS_REDIS = "redis://redis:6379";

            PAPERLESS_TRASH_DIR = "/usr/src/paperless/media/trash";

            PAPERLESS_OCR_LANGUAGES = "eng jpn jpn-vert ukr rus"; # Confusingly this only installs the language packs
            PAPERLESS_OCR_LANGUAGE = "ukr+rus+eng+jpn+jpn_vert"; # And this hints the OCR engine which languages to try to detect

            PAPERLESS_SOCIAL_AUTO_SIGNUP = "true";
            PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http";
            PAPERLESS_URL = "http://paperless.${config.custom.networking.domain}";
          };
          env_file = [ config.age.secrets.paperless_compose.path ];
          depends_on = [
            "redis"
            "postgresql"
          ];
          restart = "unless-stopped";
          volumes = [
            (storeFor "data" "/usr/src/paperless/data")
            (storeFor "export" "/usr/src/paperless/export")
            (externalStoreFor "media" "/usr/src/paperless/media")
            (externalStoreFor "media/trash" "/usr/src/paperless/media/trash")
          ];
          labels =
            (dockerLib.mkTraefikLabels { name = "paperless"; port = 8000; }) //
            {
              "wud.tag.include" = ''^\d+\.\d+\.\d+'';
              "wud.display.icon" = "si:paperlessngx";
            };
        };
      };
    };
  };
}
