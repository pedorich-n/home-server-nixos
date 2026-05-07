{
  config,
  containerLib,
  networkingLib,
  pkgs,
  ...
}:
let
  storeRoot = "/mnt/store/music-history";

  malojaArtistRules = pkgs.callPackage ./maloja/_artist-rules.nix { };

  networks = [ "music-history-internal.network" ];

  portsCfg = config.custom.networking.ports.tcp;
in
{
  custom = {
    networking.ports.tcp = {
      maloja = {
        port = 30200;
        openFirewall = false;
      };
      multiscrobbler = {
        port = 30201;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      maloja = {
        upstream = "http://localhost:${portsCfg.maloja.portStr}";
      };
      multiscrobbler = {
        upstream = "http://localhost:${portsCfg.multiscrobbler.portStr}";
        auth = "authelia";
      };
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "music-history";

    containers = {
      multiscrobbler = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = {
            inherit (containerLib.containerIds) PUID PGID;
            TZ = config.time.timeZone;

            BASE_URL = networkingLib.mkUrl "multiscrobbler";

            LOG_LEVEL = "INFO";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/multi-scrobbler/config" "/config")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/multiscrobbler/spotify.json".path "/config/spotify.json")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/multiscrobbler/maloja.json".path "/config/maloja.json")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.multiscrobbler.portStr}:9078" ];
          labels = containerLib.mkTraefikLabels {
            name = "multiscrobbler";
            port = 9078;
            middlewares = [ "authelia@file" ];
          };
          inherit networks;
        };
      };

      maloja = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = containerLib.containerIds.uid + 500;
        };

        containerConfig = {
          environments = {
            inherit (containerLib.containerIds) PUID PGID;
            MALOJA_SKIP_SETUP = "true";
            MALOJA_SEND_STATS = "false";
            MALOJA_SCROBBLE_LASTFM = "false";

            MALOJA_DATA_DIRECTORY = "/data";
            MALOJA_TIMEZONE = "9";
          };
          environmentFiles = [ config.sops.secrets."music-history/maloja.env".path ];
          publishPorts = [ "127.0.0.1:${portsCfg.maloja.portStr}:42010" ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/maloja/data" "/data")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/maloja/api_keys.yaml".path "/data/apikeys.yml")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "maloja";
            port = 42010;
          };
          inherit networks;
        };
      };
    };
  };
}
