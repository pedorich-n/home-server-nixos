{
  config,
  containerLib,
  systemdLib,
  networkingLib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/airtrail";

  networks = [ "airtrail-internal.network" ];

  portsCfg = config.custom.networking.ports.tcp.airtrail;
in
{
  custom = {
    networking.ports.tcp.airtrail = {
      port = 30400;
      openFirewall = false;
    };

    services.caddy.hosts.airtrail = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "airtrail";

    containers = {
      airtrail-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."airtrail/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      airtrail-server = {
        useGlobalContainers = true;
        wantsCaddy = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environmentFiles = [
            config.sops.secrets."airtrail/main.env".path
          ];
          environments = {
            ORIGIN = networkingLib.mkUrl "airtrail";
            UPLOAD_LOCATION = "/app/uploads";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/server/uploads" "/app/uploads")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.portStr}:3000" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.airtrail-postgresql.ref
        ];
      };
    };
  };
}
