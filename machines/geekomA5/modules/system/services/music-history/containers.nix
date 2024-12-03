{ config, dockerLib, lib, pkgs, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/music-history/${localPath}:${remotePath}";

  malojaArtistRules = pkgs.callPackage ./maloja/_artist-rules.nix { };
in
{
  systemd.targets.music-history = {
    wants = [ "multiscrobbler.service" "maloja.service" ];
  };

  virtualisation.quadlet = {
    networks = {
      music-history-internal.networkConfig.name = "music-history-internal";
    };

    containers = {
      multiscrobbler = {
        containerConfig = rec {
          image = "ghcr.io/foxxmd/multi-scrobbler:${containerVersions.multi-scrobbler}";
          name = "multiscrobbler";
          networks = [
            "music-history-internal"
            "traefik"
          ];
          environments = {
            TZ = config.time.timeZone;

            BASE_URL = "http://${name}.${config.custom.networking.domain}:80";

            LOG_LEVEL = "debug";
          };
          volumes = [
            (storeFor "multi-scrobbler/config" "/config")
            "${config.age.secrets.multi_scrobbler_spotify.path}:/config/spotify.json"
            "${config.age.secrets.multi_scrobbler_maloja.path}:/config/maloja.json"
            "${./multi-scrobbler/webscrobbler.json}:/config/webscrobbler.json"
          ];
          #TODO: make mkTraefikLabels return a list
          labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels {
            inherit name;
            port = 9078;
            middlewares = [ "authentik@docker" ];
          });
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          After = [
            "authentik.target"
          ];
        };
      };

      maloja = {
        containerConfig = rec {

          image = "krateng/maloja:${containerVersions.maloja}";
          name = "maloja";
          networks = [
            "music-history-internal"
            "traefik"
          ];
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
          #TODO: make mkTraefikLabels return a list
          labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels {
            inherit name;
            port = 42010;
            middlewares = [ "authentik@docker" ];
          });
        };

        serviceConfig = {
          Restart = "unless-stopped";
        };

        unitConfig = {
          After = [
            "authentik.target"
          ];
        };
      };
    };
  };
}
