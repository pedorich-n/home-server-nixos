{ config, containerLib, systemdLib, networkingLib, ... }:
let
  storeRoot = "/mnt/store/paperless";
  externalStoreRoot = "/mnt/external/paperless-library";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

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
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      paperless-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."paperless/postgresql.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
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
            USERMAP_UID = containerLib.containerIds.PUID;
            USERMAP_GID = containerLib.containerIds.PGID;

            PAPERLESS_DBHOST = "paperless-postgresql";
            PAPERLESS_DBENGINE = "postgres";
            PAPERLESS_REDIS = "redis://paperless-redis:6379";

            PAPERLESS_TRASH_DIR = "/usr/src/paperless/media/trash";

            PAPERLESS_OCR_LANGUAGES = "eng jpn jpn-vert ukr rus"; # Confusingly this only installs the language packs
            PAPERLESS_OCR_LANGUAGE = "ukr+rus+eng+jpn+jpn_vert"; # And this hints the OCR engine which languages to try to detect
            # https://github.com/paperless-ngx/paperless-ngx/discussions/4047#discussioncomment-7019544
            PAPERLESS_OCR_USER_ARGS = "{\"invalidate_digital_signatures\": true}";

            PAPERLESS_SOCIAL_AUTO_SIGNUP = "true";
            PAPERLESS_ACCOUNT_DEFAULT_HTTP_PROTOCOL = "https";
            PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";

            PAPERLESS_URL = networkingLib.mkExternalUrl "paperless";
          };
          environmentFiles = [
            config.sops.secrets."paperless/main.env".path
            config.sops.templates."paperless/oidc.env".path
          ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/data" "/usr/src/paperless/data")
            (mappedVolumeForUser "${storeRoot}/export" "/usr/src/paperless/export")
            (mappedVolumeForUser "${externalStoreRoot}/media" "/usr/src/paperless/media")
            (mappedVolumeForUser "${externalStoreRoot}/media/trash" "/usr/src/paperless/media/trash")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "paperless-secure";
            domain = networkingLib.mkExternalDomain "paperless";
            port = 8000;
            entrypoints = [ "web-secure" ];
          };
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter [
          "paperless-redis.service"
          "paperless-postgresql.service"
        ];
      };
    };
  };

}
