{
  config,
  containerLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/music-history";

  networks = [ "music-history-internal.network" ];

  portsCfg = config.custom.networking.ports.tcp;
in
{
  custom = {
    networking.ports.tcp = {
      multiscrobbler = {
        port = 30201;
        openFirewall = false;
      };
      koito = {
        port = 30202;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      multiscrobbler = {
        upstream = "http://127.0.0.1:${portsCfg.multiscrobbler.portStr}";
        auth = "authelia";
        routes = [
          {
            path = "/api*";
            auth = null;
          }
          {
            path = "/1*"; # ListenBrainz API webhook endpoint
            auth = null;
          }
        ];
      };
      koito = {
        upstream = "http://127.0.0.1:${portsCfg.koito.portStr}";
      };
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "music-history";

    containers = {
      multiscrobbler = {
        wantsCaddy = true;
        useGlobalContainers = true;
        useDigest = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = {
            inherit (containerLib.containerIds) PUID PGID;
            TZ = config.time.timeZone;
            # NodeJS 20+ uses IPv6 by default. I don't have IPv6 enabled, but for some reason it still tries to use it and fails with ETIMEDOUT
            # See https://github.com/nodejs/node/issues/54359
            NODE_OPTIONS = "--network-family-autoselection-attempt-timeout=5000";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/multi-scrobbler/config" "/config")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/multiscrobbler/config.json".path "/config/config.json")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.multiscrobbler.portStr}:9078" ];
          inherit networks;
        };
      };

      koito = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = {
            KOITO_LOG_LEVEL = "warn";
            KOITO_CONFIG_DIR = "/etc/config";
            KOITO_CORS_ALLOWED_ORIGINS = networkingLib.mkLocalUrl "koito";
          };
          environmentFiles = [ config.sops.secrets."music-history/koito.env".path ];
          publishPorts = [ "127.0.0.1:${portsCfg.koito.portStr}:4110" ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/koito" "/etc/config")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };
    };
  };
}
