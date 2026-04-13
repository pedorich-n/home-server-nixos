{
  config,
  pkgs,
  pkgs-unstable,
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

  settings = import ./_config.nix {
    inherit pkgs networkingLib;
    portsCfg = config.custom.networking.ports;
    mcpServersCfg = config.custom.managed-files.mcp-servers;
  };

  # LibreChat runs as 1000:1000 in the container, with no real way to remap it, so we need to map the volume with the correct permissions.
  mkMappedVolumeForCustom =
    hostPath: containerPath:
    containerLib.mkIdMappedVolume {
      inherit hostPath containerPath;
      uidMappings = [
        {
          idNamespace = 1000;
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 1000;
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
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
        # The container runs as 1000:1000 and there is no way to change it, basically.
        # Setting `user` or `UID/GID` doesnt work. There are multiple issues raised in the repo about this:
        # - https://github.com/danny-avila/LibreChat/discussions/2939
        # - https://github.com/danny-avila/LibreChat/discussions/6846
        # - https://github.com/danny-avila/LibreChat/discussions/4735
        usernsAuto.enable = true;
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthelia = true;

        containerConfig = {
          environments = {
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
            config.sops.secrets."librechat/mcps.env".path
          ];
          volumes = [
            (mkMappedVolumeForCustom "${storeRoot}/server/images" "/app/client/public/images")
            (mkMappedVolumeForCustom "${storeRoot}/server/uploads" "/app/uploads")
            (mkMappedVolumeForCustom "${storeRoot}/server/logs" "/app/logs")
            "${settings}:/app/librechat.yaml:ro"
            "/run/user/${toString config.users.users.podman-runner.uid}/podman/podman.sock:/run/podman.sock"
            "${lib.getExe pkgs-unstable.pkgsStatic.forgejo-mcp}:/usr/bin/forgejo-mcp:ro"
          ];

          labels = containerLib.mkTraefikLabels {
            name = "librechat";
            slug = "chat";
            port = 3080;
          };
          inherit networks;
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
