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

  mkMappedVolumeForUserContainerRoot =
    localPath: remotePath:
    containerLib.mkIdmappedVolume {
      uidNamespace = 0;
      gidNamespace = 0;
      uidHost = config.users.users.user.uid;
      gidHost = config.users.groups.${config.users.users.user.group}.gid;
    } localPath remotePath;
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
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql")
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

      paperless-gpt = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = {
            PAPERLESS_BASE_URL = "http://paperless-server:8000";
            PAPERLESS_API_TOKEN = "<TOKEN>"; # TODO
            PAPERLESS_PUBLIC_URL = networkingLib.mkUrl "paperless";

            LLM_PROVIDER = "ollama";
            LLM_MODEL = "qwen3:8b";
            OLLAMA_HOST = networkingLib.mkUrl "ollama";
            OLLAMA_CONTEXT_LENGTH = "8192";
            TOKEN_LIMIT = "1000";

            MANUAL_TAG = "paperless-gpt";
            AUTO_TAG = "paperless-gpt-auto";

            AUTO_GENERATE_TITLE = "true";
            AUTO_GENERATE_CREATED_DATE = "true";
            AUTO_GENERATE_TAGS = "false";
            AUTO_GENERATE_CORRESPONDENTS = "false";

            OCR_PROVIDER = "google_docai";
            GOOGLE_PROJECT_ID = "<ID>"; # TODO
            GOOGLE_LOCATION = "eu";
            GOOGLE_PROCESSOR_ID = "<ID>"; # TODO
            CREATE_LOCAL_HOCR = "true";
            CREATE_LOCAL_PDF = "true";
            GOOGLE_APPLICATION_CREDENTIALS = "/app/google-credentials.json";

            OCR_PROCESS_MODE = "pdf";
            OCR_LIMIT_PAGES = "10";
            PDF_SKIP_EXISTING_OCR = "false";

            PDF_UPLOAD = "true";
            PDF_COPY_METADATA = "true";
            PDF_REPLACE = "false";
            PDF_OCR_TAGGING = "false";
          };
          volumes = [
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/paperless-gpt/hocr" "/app/hocr")
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/paperless-gpt/pdf" "/app/pdf")
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/paperless-gpt/prompts" "/app/prompts")
            # (mkMappedVolumeForUserContainerRoot "${./paperless-gpt-credentials.json}" "/app/google-credentials.json")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "paperless-gpt-secure";
            port = 8080;
          };
          inherit networks;
          # inherit (containerLib.containerIds) user;
        };
      };
    };
  };

}
