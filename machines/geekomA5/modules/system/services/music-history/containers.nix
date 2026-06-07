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
      koito = {
        port = 30202;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      multiscrobbler = {
        upstream = "http://127.0.0.1:${portsCfg.multiscrobbler.portStr}";
        auth = "authelia";
      };
      koito = {
        upstream = "http://127.0.0.1:${portsCfg.koito.portStr}";
      };
    };
  };

  services.caddy.virtualHosts."${networkingLib.mkDomain "maloja"}" = {
    logFormat = null;
    useACMEHost = "local";
    extraConfig = ''
      reverse_proxy http://127.0.0.1:${portsCfg.maloja.portStr} {
        # Maloja goes bonkers from Authelia's and other cookies set for the TLD,
        # so we only leave cookies prefixed with `maloja` and `adminmode` and strip the rest.
        header_up Cookie "(?i)(maloja[^=]*=[^;]*;?\s*)|(adminmode=[^;]*;?\s*)|[^;]+;?\s*" "$1$2"
      }
      import error-handler
    '';

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
            # NodeJS 20+ uses IPv6 by default. I don't have IPv6 enabled, but for some reason it still tries to use it and fails with ETIMEDOUT
            # See https://github.com/nodejs/node/issues/54359
            NODE_OPTIONS = "--network-family-autoselection-attempt-timeout=3000";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/multi-scrobbler/config" "/config")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/multiscrobbler/config.json".path "/config/config.json")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.multiscrobbler.portStr}:9078" ];
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
            KOITO_CORS_ALLOWED_ORIGINS = networkingLib.mkUrl "koito";
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
