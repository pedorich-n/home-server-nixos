{ config, containerLib, pkgs, ... }:
let
  storeRoot = "/mnt/store/music-history";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

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

            BASE_URL = "http://multiscrobbler.${config.custom.networking.domain}:80";

            LOG_LEVEL = "INFO";
          };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/multi-scrobbler/config" "/config")
            "${config.sops.templates."music-history/multiscrobbler/spotify.json".path}:/config/spotify.json"
            "${config.sops.templates."music-history/multiscrobbler/maloja.json".path}:/config/maloja.json"
            "${./multi-scrobbler/webscrobbler.json}:/config/webscrobbler.json"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "multiscrobbler";
            port = 9078;
            middlewares = [ "authentik@docker" ];
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
            (mappedVolumeForUser "${storeRoot}/maloja/data" "/data")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
            "${config.sops.templates."music-history/maloja/api_keys.yaml".path}:/data/apikeys.yml"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "maloja";
            port = 42010;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks;
        };
      };
    };
  };
}
