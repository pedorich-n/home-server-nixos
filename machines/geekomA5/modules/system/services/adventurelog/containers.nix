{ config, systemdLib, containerLib, ... }:
let
  storeRoot = "/mnt/store/adventurelog";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

  networks = [ "adventurelog-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "adventurelog";

    containers = {
      adventurelog-postgis = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."adventurelog/postgis.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgis" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      adventurelog-backend = {
        useGlobalContainers = true;
        # usernsAuto.enable = true;
        requiresTraefikNetwork = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."adventurelog/main.env".path ];
          environments = {
            PGHOST = "adventurelog-postgis";
            PUBLIC_URL = "http://adventurelog.${config.custom.networking.domain}";
            FRONTEND_URL = "http://adventurelog.${config.custom.networking.domain}";
            CSRF_TRUSTED_ORIGINS = "http://adventurelog.${config.custom.networking.domain}";
            DEBUG = "true";
          };
          volumes = [
            "${storeRoot}/media:/code/media"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "adventurelog-backend";
            rule = "'Host(`adventurelog.${config.custom.networking.domain}`) && (PathPrefix(`/media`) || PathPrefix(`/admin`) || PathPrefix(`/static`) || PathPrefix(`/accounts`))'";
            port = 80;
            # middlewares = [ "authentik@docker" ];
          };

          inherit networks;
          # inherit (containerLib.containerIds) user;
        };


        unitConfig = systemdLib.requiresAfter
          [
            "adventurelog-postgis.service"
          ]
          { };
      };

      adventurelog-frontend = {
        useGlobalContainers = true;
        usernsAuto.enable = true;
        requiresTraefikNetwork = true;

        containerConfig = {
          addHosts = [
            "adventurelog-backend.${config.custom.networking.domain}:192.168.10.15"
          ];
          environments = {
            PUBLIC_SERVER_URL = "http://adventurelog-backend:8000";
            ORIGIN = "http://adventurelog.${config.custom.networking.domain}";
          };
          labels = containerLib.mkTraefikLabels {
            name = "adventurelog-frontend";
            rule = "'Host(`adventurelog.${config.custom.networking.domain}`) && !(PathPrefix(`/media`) || PathPrefix(`/admin`) || PathPrefix(`/static`) || PathPrefix(`/accounts`))'";
            port = 3000;
            # middlewares = [ "authentik@docker" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "adventurelog-backend.service"
          ]
          { };
      };
    };
  };
}
