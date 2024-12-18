{ config, containerLib, pkgs, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/music-history/${localPath}:${remotePath}";

  malojaArtistRules = pkgs.callPackage ./maloja/_artist-rules.nix { };

  pod = "music-history.pod";
  networks = [ "music-history-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "music-history";

    pods.music-history = {
      podConfig = { inherit networks; };
    };

    containers = {
      multiscrobbler = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = config.time.timeZone;

            BASE_URL = "http://multiscrobbler.${config.custom.networking.domain}:80";

            LOG_LEVEL = "debug";
          };
          volumes = [
            (storeFor "multi-scrobbler/config" "/config")
            "${config.age.secrets.multi_scrobbler_spotify.path}:/config/spotify.json"
            "${config.age.secrets.multi_scrobbler_maloja.path}:/config/maloja.json"
            "${./multi-scrobbler/webscrobbler.json}:/config/webscrobbler.json"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "multiscrobbler";
            port = 9078;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };

      maloja = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            MALOJA_SKIP_SETUP = "true";
            MALOJA_SEND_STATS = "false";
            MALOJA_SCROBBLE_LASTFM = "false";

            MALOJA_DATA_DIRECTORY = "/data";
            MALOJA_TIMEZONE = "9";
          };
          environmentFiles = [ config.age.secrets.music_history.path ];
          volumes = [
            (storeFor "maloja/data" "/data")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
            "${config.age.secrets.maloja_apikeys.path}:/data/apikeys.yml"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "maloja";
            port = 42010;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };
    };
  };
}
