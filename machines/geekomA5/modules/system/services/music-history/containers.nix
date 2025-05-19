{ config, containerLib, networkingLib, pkgs, ... }:
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
            (mappedVolumeForUser config.sops.templates."music-history/multiscrobbler/spotify.json".path "/config/spotify.json")
            (mappedVolumeForUser config.sops.templates."music-history/multiscrobbler/maloja.json".path "/config/maloja.json")
            "${./multi-scrobbler/webscrobbler.json}:/config/webscrobbler.json"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "multiscrobbler-secure";
            domain = networkingLib.mkExternalDomain "multiscrobbler";
            port = 9078;
            entrypoints = [ "web-secure" ];
            middlewares = [ "authentik-secure@docker" ];
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
            (mappedVolumeForUser config.sops.templates."music-history/maloja/api_keys.yaml".path "/data/apikeys.yml")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "maloja";
            domain = networkingLib.mkExternalDomain "maloja";
            port = 42010;
            entrypoints = [ "web-secure" ];
            middlewares = [ "authentik-secure@docker" ];
          };
          inherit networks;
        };
      };
    };
  };
}
