{ config, containerLib, systemdLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/paperless/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: "/mnt/external/paperless-library/${localPath}:${remotePath}";

  pod = "paperless.pod";
  networks = [ "paperless-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "paperless";

    pods.paperless = {
      podConfig = { inherit networks; };
    };

    containers = {
      paperless-redis = {
        useGlobalContainers = true;

        containerConfig = {
          volumes = [
            (storeFor "redis" "/data")
          ];
          inherit networks pod;
        };
      };

      paperless-postgresql = {
        useGlobalContainers = true;
        containerConfig = {
          environmentFiles = [ config.age.secrets.paperless.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks pod;
        };
      };

      paperless-server = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;

        containerConfig = {
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
          labels = containerLib.mkTraefikLabels { name = "paperless"; port = 8000; };
          inherit networks pod;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "paperless-redis.service"
            "paperless-postgresql.service"
          ]
          { };
      };
    };
  };

}
