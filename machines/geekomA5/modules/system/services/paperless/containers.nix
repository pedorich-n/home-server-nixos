{
  config,
  containerLib,
  systemdLib,
  networkingLib,
  lib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/paperless";
  externalStoreRoot = "/mnt/external/paperless-library";

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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/redis" "/data")
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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      paperless-server = {
        requiresTraefikNetwork = true;
        wantsAuthelia = true;
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

            PAPERLESS_URL = networkingLib.mkUrl "paperless";
          };
          environmentFiles = [
            config.sops.secrets."paperless/main.env".path
            config.sops.templates."paperless/oidc.env".path
          ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/data" "/usr/src/paperless/data")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/export" "/usr/src/paperless/export")
            (containerLib.mkMappedVolumeForUser "${externalStoreRoot}/media" "/usr/src/paperless/media")
            (containerLib.mkMappedVolumeForUser "${externalStoreRoot}/media/trash" "/usr/src/paperless/media/trash")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "paperless-secure";
            port = 8000;
          };
          inherit networks;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.paperless-redis.ref
            containers.paperless-postgresql.ref
          ])
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };
    };
  };

}
