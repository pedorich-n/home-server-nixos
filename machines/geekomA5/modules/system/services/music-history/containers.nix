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
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "music-history";

    containers = {
      multiscrobbler = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
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
          labels = containerLib.mkTraefikLabels {
            name = "multiscrobbler-secure";
            port = 9078;
            middlewares = [ "authelia@file" ];
          };
          inherit networks;
        };
      };

      maloja = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
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
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/maloja/data" "/data")
            (containerLib.mkMappedVolumeForUser config.sops.templates."music-history/maloja/api_keys.yaml".path "/data/apikeys.yml")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "maloja-secure";
            port = 42010;
            middlewares = [ "authelia@file" ];
          };
          inherit networks;
        };
      };
    };
  };
}
