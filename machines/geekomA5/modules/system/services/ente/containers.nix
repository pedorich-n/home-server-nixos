{ config, containerLib, systemdLib, networkingLib, ... }:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/ente";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;


  networks = [ "ente-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "ente";

    containers = {
      ente-postgresql = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."ente/postgresql.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      ente-museum = {
        useGlobalContainers = false;
        requiresTraefikNetwork = true;
        usernsAuto.enable = true;

        containerConfig = {
          image = "ghcr.io/ente-io/server:latest";
          volumes = [
            (mappedVolumeForUser "${storeRoot}/museum/data" "/data")
            (mappedVolumeForUser config.sops.templates."ente/museum.yaml".path "/museum.yaml")
          ];

          labels = containerLib.mkTraefikLabels {
            name = "ente-museum-secure";
            slug = "ente-api";
            port = 8080;
          };

          inherit networks;
          inherit (containerLib.containerIds) user;
        };


        unitConfig = systemdLib.requiresAfter [
          containers.ente-postgresql.ref
        ];
      };

      ente-web = {
        useGlobalContainers = false;
        requiresTraefikNetwork = true;
        usernsAuto.enable = true;

        containerConfig = {
          image = "ghcr.io/ente-io/web:latest";
          environments = {
            ENTE_API_ORIGIN = networkingLib.mkUrl "ente-api";
          };

          labels = (containerLib.mkTraefikLabels {
            name = "ente-photos-web-secure";
            slug = "ente";
            port = 3000;
          }) ++ (containerLib.mkTraefikLabels {
            name = "ente-accounts-web-secure";
            slug = "ente-accounts";
            port = 3001;
          });

          inherit networks;
          # inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.ente-postgresql.ref
          containers.ente-museum.ref
        ];
      };
    };

  };

}
