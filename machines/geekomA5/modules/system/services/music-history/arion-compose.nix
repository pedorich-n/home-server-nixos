{ config, dockerLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/music-history/${localPath}:${remotePath}";
  # externalStoreFor = localPath: remotePath: "/mnt/external/music-history/${localPath}:${remotePath}";
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
          image = "foxxmd/multi-scrobbler@sha256:e52865983c3c105984dd588361bf3a1009eb0fc87cd53b60b7f6fc7b9857e092";
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
          labels = (dockerLib.mkTraefikLabels {
            name = container_name;
            port = 9078;
            middlewares = [ "authentik@docker" ];
          }) //
          (dockerLib.mkHomepageLabels {
            name = "Multi Scrobbler";
            group = "Services";
            icon-slug = "multi-scrobbler";
            weight = 90;
          });
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
            "${./maloja/rules}:/data/rules"
            "${config.age.secrets.maloja_apikeys.path}:/data/apikeys.yml"
          ];
          restart = "unless-stopped";
          labels = (dockerLib.mkTraefikLabels {
            name = container_name;
            port = 42010;
            middlewares = [ "authentik@docker" ];
          }) //
          (dockerLib.mkHomepageLabels {
            name = "Maloja";
            group = "Services";
            weight = 100;
          });
        };
      };
    };
  };
}
