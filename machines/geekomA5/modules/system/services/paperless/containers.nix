{ config, containerLib, systemdLib, ... }:
let
  storeRoot = "/mnt/store/paperless";
  externalStoreRoot = "/mnt/external/paperless-library";

  containerIds = {
    uid = 1100;
    gid = 1100;
  };

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

  user = "${builtins.toString containerIds.uid}:${builtins.toString containerIds.gid}";

  networks = [ "paperless-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "paperless";

    containers = {
      paperless-redis = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          volumes = [
            (mappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks user;
        };
      };

      paperless-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.age.secrets.paperless.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks user;
        };
      };

      paperless-server = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = {
            USERMAP_UID = builtins.toString containerIds.uid;
            USERMAP_GID = builtins.toString containerIds.gid;

            PAPERLESS_DBHOST = "paperless-postgresql";
            PAPERLESS_DBENGINE = "postgres";
            PAPERLESS_REDIS = "redis://paperless-redis:6379";

            PAPERLESS_TRASH_DIR = "/usr/src/paperless/media/trash";

            PAPERLESS_OCR_LANGUAGES = ''"eng jpn jpn-vert ukr rus"''; # Confusingly this only installs the language packs
            PAPERLESS_OCR_LANGUAGE = "ukr+rus+eng+jpn+jpn_vert"; # And this hints the OCR engine which languages to try to detect
            # https://github.com/paperless-ngx/paperless-ngx/discussions/4047#discussioncomment-7019544
            PAPERLESS_OCR_USER_ARGS = "'{\"invalidate_digital_signatures\": true}'";

            PAPERLESS_SOCIAL_AUTO_SIGNUP = "true";
            PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http";
            PAPERLESS_URL = "http://paperless.${config.custom.networking.domain}";
          };
          environmentFiles = [ config.age.secrets.paperless.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/data" "/usr/src/paperless/data")
            (mappedVolumeForUser "${storeRoot}/export" "/usr/src/paperless/export")
            (mappedVolumeForUser "${externalStoreRoot}/media" "/usr/src/paperless/media")
            (mappedVolumeForUser "${externalStoreRoot}/media/trash" "/usr/src/paperless/media/trash")
          ];
          labels = containerLib.mkTraefikLabels { name = "paperless"; port = 8000; };
          inherit networks;
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
