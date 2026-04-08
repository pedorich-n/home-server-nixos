{
  config,
  pkgs,
  containerLib,
  systemdLib,
  networkingLib,
  autheliaLib,
  lib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/librechat";

  networks = [ "librechat-internal.network" ];

  settings = import ./_config.nix { inherit pkgs; };
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "librechat";

    containers = {
      librechat-mongodb = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/mongodb" "/data/db")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      librechat-postgresql = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."librechat/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      librechat-rag = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            DB_HOST = "librechat-postgresql";
            RAG_PORT = "8000";
          };
          environmentFiles = [
            config.sops.secrets."librechat/rag.env".path
            config.sops.secrets."librechat/apis.env".path
          ];
          inherit networks;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.librechat-postgresql.ref
          ])
        ];
      };

      librechat-server = {
        # usernsAuto.enable = true;
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthelia = true;

        containerConfig = {
          environments = {
            UID = containerLib.containerIds.PUID;
            GID = containerLib.containerIds.PGID;

            MONGO_URI = "mongodb://librechat-mongodb:27017/LibreChat";
            RAG_API_URL = "http://librechat-rag:8000";

            TRUST_PROXY = "1";
            DOMAIN_CLIENT = networkingLib.mkUrl "chat";
            DOMAIN_SERVER = networkingLib.mkUrl "chat";

            SEARCH = "false";

            ALLOW_REGISTRATION = "false";
            ALLOW_SOCIAL_LOGIN = "true";
            ALLOW_SOCIAL_REGISTRATION = "true";
            OPENID_BUTTON_LABEL = "Log in with Authelia";
            OPENID_ISSUER = autheliaLib.issuerUrl;
            OPENID_CALLBACK_URL = "/oauth/openid/callback";
            OPENID_SCOPE = "openid profile email roles";
            OPENID_ADMIN_ROLE = "admin";
            OPENID_ADMIN_ROLE_TOKEN_KIND = "userinfo";
            OPENID_ADMIN_ROLE_PARAMETER_PATH = "roles";
            OPENID_USERNAME_CLAIM = "preferred_username";
            OPENID_NAME_CLAIM = "name";
            OPENID_USE_END_SESSION_ENDPOINT = "false";
          };
          environmentFiles = [
            config.sops.secrets."librechat/server.env".path
            config.sops.secrets."librechat/apis.env".path
          ];
          volumes = [
            # (containerLib.mkMappedVolumeForUser "${storeRoot}/server/images" "/app/client/public/images")
            # (containerLib.mkMappedVolumeForUser "${storeRoot}/server/uploads" "/app/uploads")
            # (containerLib.mkMappedVolumeForUser "${storeRoot}/server/logs" "/app/logs")
            "${storeRoot}/server/images:/app/client/public/images"
            "${storeRoot}/server/uploads:/app/uploads"
            "${storeRoot}/server/logs:/app/logs"
            "${settings}:/app/librechat.yaml:ro"
          ];

          labels = containerLib.mkTraefikLabels {
            name = "librechat";
            slug = "chat";
            port = 3080;
          };
          inherit networks;
          # inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.librechat-rag.ref
            containers.librechat-mongodb.ref
          ])
        ];
      };

    };
  };

}
