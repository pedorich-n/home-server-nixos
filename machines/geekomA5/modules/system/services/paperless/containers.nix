{ config, containerLib, systemdLib, ... }:
let
  user = "${builtins.toString config.users.users.user.uid}:${builtins.toString config.users.groups.${config.users.users.user.group}.gid}";
  storeFor = localPath: remotePath: "/mnt/store/paperless/${localPath}:${remotePath}";


  storeRoot = "/mnt/store/paperless";
  externalStoreRoot = "/mnt/external/paperless-library";

  mappedVolumeForUser = uidNamespace: gidNamespace: localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        inherit uidNamespace;
        uidHost = config.users.users.user.uid;
        uidCount = 1;
        uidRelative = true;
        inherit gidNamespace;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
        gidCount = 1;
        gidRelative = true;
      }
      localPath
      remotePath;

  pod = "paperless.pod";
  networks = [ "paperless-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "paperless";

    pods.paperless = {
      podConfig = {
        inherit networks;
        # userns = "auto";
      };
    };

    containers = {
      paperless-redis = {
        useGlobalContainers = true;

        containerConfig = {
          userns = "auto";
          volumes = [
            # https://github.com/redis/docker-library-redis/blob/8338d86bc3f/Dockerfile.template#L11-L12
            (mappedVolumeForUser 999 1000 "${storeRoot}/redis" "/data")
          ];
          inherit networks;
        };
      };

      paperless-postgresql = {
        useGlobalContainers = true;

        containerConfig = {
          # userns = "auto";
          # user = "70:70";
          environmentFiles = [ config.age.secrets.paperless.path ];
          volumes = [
            # https://github.com/docker-library/postgres/blob/cb049360/Dockerfile-alpine.template#L10-L11
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks pod user;
        };
      };

      paperless-server = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;
        # usernsAuto = true;

        containerConfig = {
          environments = {
            # USERMAP_UID = builtins.toString config.users.users.user.uid;
            # USERMAP_GID = builtins.toString config.users.groups.${config.users.users.user.group}.gid;

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
          userns = "auto:size=65535";
          volumes = [
            # https://github.com/paperless-ngx/paperless-ngx/blob/7035445d6a8/Dockerfile#L267-L268
            (mappedVolumeForUser 1000 1000 "${storeRoot}/data" "/usr/src/paperless/data")
            (mappedVolumeForUser 1000 1000 "${storeRoot}/export" "/usr/src/paperless/export")
            (mappedVolumeForUser 1000 1000 "${externalStoreRoot}/media" "/usr/src/paperless/media")
            (mappedVolumeForUser 1000 1000 "${externalStoreRoot}/media/trash" "/usr/src/paperless/media/trash")
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
