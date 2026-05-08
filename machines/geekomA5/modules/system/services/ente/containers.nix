{
  config,
  containerLib,
  systemdLib,
  networkingLib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  portsCfg = config.custom.networking.ports.tcp;

  storeRoot = "/mnt/store/ente";

  networks = [ "ente-internal.network" ];
in
{
  custom = {
    networking.ports.tcp = {
      ente-museum = {
        port = 30600;
        openFirewall = false;
      };
      ente-photos = {
        port = 30601;
        openFirewall = false;
      };
      ente-accounts = {
        port = 30602;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      "ente-api" = {
        upstream = "http://localhost:${portsCfg.ente-museum.portStr}";
      };
      "ente" = {
        upstream = "http://localhost:${portsCfg.ente-photos.portStr}";
      };
      "ente-accounts" = {
        upstream = "http://localhost:${portsCfg.ente-accounts.portStr}";
      };
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "ente";

    containers = {
      ente-postgresql = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."ente/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      ente-museum = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/museum/data" "/data")
            (containerLib.mkMappedVolumeForUser config.sops.templates."ente/museum.yaml".path "/museum.yaml")
          ];

          publishPorts = [ "127.0.0.1:${portsCfg.ente-museum.portStr}:8080" ];

          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.ente-postgresql.ref
        ];
      };

      ente-web = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = {
            ENTE_API_ORIGIN = networkingLib.mkUrl "ente-api";
          };

          publishPorts = [
            "127.0.0.1:${portsCfg.ente-photos.portStr}:3000"
            "127.0.0.1:${portsCfg.ente-accounts.portStr}:3001"
          ];

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
