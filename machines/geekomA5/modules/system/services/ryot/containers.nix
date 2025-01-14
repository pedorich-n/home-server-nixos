{ config, containerLib, systemdLib, ... }:
let
  storeRoot = "/mnt/store/ryot";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;


  networks = [ "ryot-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "ryot";

    containers = {
      ryot-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.age.secrets.ryot_postgresql.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      ryot = {
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";

            FRONTEND_URL = "http://ryot.${config.custom.networking.domain}";
            SERVER_OIDC_ISSUER_URL = "http://authentik.server.lan/application/o/ryot/";
            FRONTEND_OIDC_BUTTON_LABEL = "Authentik";
          };
          environmentFiles = [ config.age.secrets.ryot.path ];
          labels = containerLib.mkTraefikLabels { name = "ryot"; port = 8000; };
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter
          [ "ryot-postgresql.service" ]
          { };
      };

    };
  };
}
