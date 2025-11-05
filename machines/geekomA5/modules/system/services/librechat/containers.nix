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

  storeRoot = "/mnt/store/librechat";

  networks = [ "librechat-internal.network" ];
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
          environmentFiles = [ config.sops.secrets."librechat/rag.env".path ];
          inherit networks;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.librechat-postgresql.ref
          ])
        ];
      };

      librechat-server = {
        usernsAuto.enable = true;
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthelia = true;

        containerConfig = {
          environments = {
            MONGO_URL = "mongodb://librechat-mongodb:27017/LibreChat";
            RAG_API_URL = "http://librechat-rag:8000";

            TRUST_PROXY = "1";
            DOMAIN_CLIENT = networkingLib.mkUrl "chat";
            DOMAIN_SERVER = networkingLib.mkUrl "chat";

            SEARCH = "false";

            ALLOW_REGISTRATION = "false";
            ALLOW_SOCIAL_LOGIN = "true";
            ALLOW_SOCIAL_REGISTRATION = "true";

          };
          environmentFiles = [ config.sops.secrets."librechat/server.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/server/images" "/app/client/public/images")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/server/uploads" "/app/uploads")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/server/logs" "/app/logs")
          ];

          labels = containerLib.mkTraefikLabels {
            name = "librechat-secure";
            slug = "chat";
            port = 3080;
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
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
