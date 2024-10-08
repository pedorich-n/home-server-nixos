{ config, dockerLib, pkgs, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/music-history/${localPath}:${remotePath}";
  # externalStoreFor = localPath: remotePath: "/mnt/external/music-history/${localPath}:${remotePath}";

  malojaArtistRules = pkgs.callPackage ./maloja/_artist-rules.nix { };
in
{
  # systemd.services.arion-music-history = {
  #   requires = [
  #     #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix:72
  #     "zfs-mounted-external-paperless.service"
  #   ];
  # };

  virtualisation.arion.projects = {
    music-history.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "music-history") // dockerLib.externalTraefikNetwork;

      services = {
        multiscrobbler.service = rec {
          # Not yet deployed in any version, so keeping it to a specific tag
          image = "ghcr.io/foxxmd/multi-scrobbler:develop@sha256:578cf485b108deae544f7c63247340b77b1384eab074e1b14cd62768593c1cf6";
          container_name = "multiscrobbler";
          networks = [
            "default"
            "traefik"
          ];
          environment = {
            TZ = config.time.timeZone;

            BASE_URL = "http://${container_name}.${config.custom.networking.domain}:80";

            LOG_LEVEL = "debug";
          };
          volumes = [
            (storeFor "multi-scrobbler/config" "/config")
            "${config.age.secrets.multi_scrobbler_spotify.path}:/config/spotify.json"
            "${config.age.secrets.multi_scrobbler_maloja.path}:/config/maloja.json"
          ];
          restart = "unless-stopped";
          labels = dockerLib.mkTraefikLabels {
            name = container_name;
            port = 9078;
            middlewares = [ "authentik@docker" ];
          };
        };

        maloja.service = rec {
          image = "krateng/maloja:${containerVersions.maloja}";
          container_name = "maloja";
          networks = [
            "default"
            "traefik"
          ];
          environment = {
            MALOJA_SKIP_SETUP = "true";
            MALOJA_SEND_STATS = "false";
            MALOJA_SCROBBLE_LASTFM = "false";

            MALOJA_DATA_DIRECTORY = "/data";
            MALOJA_TIMEZONE = "9";
          };
          env_file = [ config.age.secrets.music_history_compose.path ];
          volumes = [
            (storeFor "maloja/data" "/data")
            "${malojaArtistRules}:/data/rules/custom_rules.tsv"
            "${config.age.secrets.maloja_apikeys.path}:/data/apikeys.yml"
          ];
          restart = "unless-stopped";
          labels = dockerLib.mkTraefikLabels {
            name = container_name;
            port = 42010;
            middlewares = [ "authentik@docker" ];
          };
        };
      };
    };
  };
}
