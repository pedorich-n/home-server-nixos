{
  config,
  containerLib,
  systemdLib,
  networkingLib,
  autheliaLib,
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

            OAUTH_ENABLED = "true";
            # Yes, this is correct. This url is used as discovery: https://github.com/johanohly/AirTrail/blob/55c5d710a68b432d6/src/lib/server/utils/oauth.ts#L61
            OAUTH_ISSUER_URL = autheliaLib.discoveryUrl;
            OAUTH_SCOPE = "openid profile email";
            OAUTH_AUTO_REGISTER = "true";
            OAUTH_BUTTON_TEXT = "Log in with Authelia";
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
