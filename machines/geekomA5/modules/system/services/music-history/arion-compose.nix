{ config, dockerLib, ... }:
let

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
        "multi-scrobbler".service = rec {
          image = "foxxmd/multi-scrobbler:0.7.1";
          container_name = "multi-scrobbler";
          networks = [
            "default"
            "traefik"
          ];
          environment = {
            TZ = config.time.timeZone;

            BASE_URL = "http://multi-scrobbler.${config.custom.networking.domain}:80";
          };
          volumes = [
            (storeFor "multi-scrobbler/config" "/config")
            "${config.age.secrets.multi_scrobbler_spotify.path}:/config/spotify.json"
            "${config.age.secrets.multi_scrobbler_maloja.path}:/config/maloja.json"
          ];
          restart = "unless-stopped";
          labels = (dockerLib.mkTraefikLabels { name = container_name; port = 9078; }) // {
            "wud.tag.include" = ''^\d+\.\d+\.\d+'';
          };
        };

        maloja.service = rec {
          image = "krateng/maloja:3.2.2";
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
          labels = (dockerLib.mkTraefikLabels { name = container_name; port = 42010; }) // {
            "wud.tag.include" = ''^\d+\.\d+\.\d+'';
          };
        };
      };
    };
  };
}
