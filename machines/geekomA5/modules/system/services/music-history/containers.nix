{ config, containerLib, pkgs, ... }:
let
  storeRoot = "/mnt/store/music-history";

  containerIds = {
    uid = 1100;
    gid = 1100;
  };

  PUID_GUID = {
    PUID = builtins.toString containerIds.uid;
    PGID = builtins.toString containerIds.gid;
  };

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidNamespace = containerIds.uid;
        uidHost = config.users.users.user.uid;
        uidCount = 1;
        uidRelative = true;
        gidNamespace = containerIds.gid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
        gidCount = 1;
        gidRelative = true;
      }
      localPath
      remotePath;

  malojaArtistRules = pkgs.callPackage ./maloja/_artist-rules.nix { };

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
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = PUID_GUID // {
            TZ = config.time.timeZone;

            BASE_URL = "http://multiscrobbler.${config.custom.networking.domain}:80";

            LOG_LEVEL = "debug";
          };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/multi-scrobbler/config" "/config")
            "${config.age.secrets.multi_scrobbler_spotify.path}:/config/spotify.json"
            "${config.age.secrets.multi_scrobbler_maloja.path}:/config/maloja.json"
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
          size = containerIds.uid + 500;
        };

        containerConfig = {
          environments = PUID_GUID // {
            MALOJA_SKIP_SETUP = "true";
            MALOJA_SEND_STATS = "false";
            MALOJA_SCROBBLE_LASTFM = "false";

            MALOJA_DATA_DIRECTORY = "/data";
            MALOJA_TIMEZONE = "9";
          };
          environmentFiles = [ config.age.secrets.music_history.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/maloja/data" "/data")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
            "${config.age.secrets.maloja_apikeys.path}:/data/apikeys.yml"
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
