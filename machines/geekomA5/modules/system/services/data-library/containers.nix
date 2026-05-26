{
  config,
  lib,
  containerLib,
  systemdLib,
  networkingLib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  networks = [ "data-library-internal.network" ];

  defaultEnvs = {
    TZ = "${config.time.timeZone}";
  };

  storeRoot = "/mnt/store/data-library";
  externalStoreRoot = "/mnt/external/data-library";

  afterDownloaders = systemdLib.wantsAfter [
    containers.qbittorrent.ref
    containers.sabnzbd.ref
    containers.gluetun.ref
  ];

  portsCfg = config.custom.networking.ports.tcp;
in
{
  custom = {
    networking.ports.tcp = {
      qbittorrent = {
        port = 30800;
        openFirewall = false;
      };
      sabnzbd = {
        port = 30900;
        openFirewall = false;
      };
      prowlarr = {
        port = 31000;
        openFirewall = false;
      };
      sonarr = {
        port = 31100;
        openFirewall = false;
      };
      radarr = {
        port = 31200;
        openFirewall = false;
      };
      shelfmark = {
        port = 31400;
        openFirewall = false;
      };
      audiobookshelf = {
        port = 31900;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      qbittorrent = {
        upstream = "http://127.0.0.1:${portsCfg.qbittorrent.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      sabnzbd = {
        upstream = "http://127.0.0.1:${portsCfg.sabnzbd.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      prowlarr = {
        upstream = "http://127.0.0.1:${portsCfg.prowlarr.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      sonarr = {
        upstream = "http://127.0.0.1:${portsCfg.sonarr.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      radarr = {
        upstream = "http://127.0.0.1:${portsCfg.radarr.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      shelfmark = {
        upstream = "http://127.0.0.1:${portsCfg.shelfmark.portStr}";
      };
      audiobookshelf = {
        upstream = "http://127.0.0.1:${portsCfg.audiobookshelf.portStr}";
      };
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "data-library";

    containers = {
      gluetun = {
        wantsCaddy = true;
        useGlobalContainers = true;

        containerConfig = {
          addCapabilities = [
            "NET_ADMIN"
            "NET_RAW"
          ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          environments = {
            BLOCK_MALICIOUS = "off";

            VPN_TYPE = "wireguard";
            SERVER_COUNTRIES = "Japan";
            VPN_SERVICE_PROVIDER = "airvpn";

            HTTP_CONTROL_SERVER_LOG = "off";
          };
          environmentFiles = [ config.sops.secrets."data-library/gluetun.env".path ];
          # https://github.com/qdm12/gluetun/blob/ddd9f4d0210c35d062896ffa2c7dc6e585deddfb/Dockerfile#L226
          healthCmd = "/gluetun-entrypoint healthcheck";
          healthStartPeriod = "15s";
          healthTimeout = "5s";
          healthInterval = "30s";
          healthRetries = 5;
          notify = "healthy";
          volumes = [
            "${./gluetun/config.toml}:/gluetun/auth/config.toml"
          ];
          publishPorts = [
            "127.0.0.1:${portsCfg.qbittorrent.portStr}:8080" # Qbittorrent Web UI
          ];
          inherit networks;
        };
      };

      qbittorrent = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = containerLib.containerIds.uid + 500;
        };

        containerConfig = {
          environments = defaultEnvs // {
            inherit (containerLib.containerIds) PUID PGID;
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/qbittorrent/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/downloads/torrent" "/data/downloads/torrent")
            "${./qbittorrent/auto_unrar.sh}:/opt/scripts/auto_unrar.sh"
          ];
          networks = [ "gluetun.container" ];
        };

        unitConfig = lib.mkMerge [
          {
            Wants = [
              containers.gluetun.ref
            ];
          }
          (systemdLib.bindsToAfter [
            containers.gluetun.ref
          ])
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];

        serviceConfig = {
          RestartSec = 5;
        };
      };

      mamapi = {
        autoStart = true; # New VPN seems to be using the same ASN every time, but better keep it running
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          environmentFiles = [ config.sops.secrets."data-library/mamapi.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/mamapi/data" "/data")
          ];
          networks = [ "gluetun.container" ];
          inherit (containerLib.containerIds) user;
        };
        unitConfig = lib.mkMerge [
          {
            PartOf = [
              containers.gluetun.ref
            ];
          }
          (systemdLib.bindsToAfter [
            containers.gluetun.ref
          ])
        ];

        serviceConfig = {
          RestartSec = 5;
        };
      };

      sabnzbd = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = rec {
          environments = defaultEnvs // {
            PORT = "8080";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/sabnzbd/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/downloads/usenet" "/data/downloads/usenet")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.sabnzbd.portStr}:${environments.PORT}" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requisiteAfter [
          "zfs.target"
        ];
      };

      prowlarr = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/prowlarr/config" "/config")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.prowlarr.portStr}:9696" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = afterDownloaders;
      };

      sonarr = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/sonarr/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia externalStoreRoot "/data")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.sonarr.portStr}:8989" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          afterDownloaders
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };

      radarr = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/radarr/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia externalStoreRoot "/data")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.radarr.portStr}:7878" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          afterDownloaders
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };

      audiobookshelf = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;
        wantsAuthelia = true;

        containerConfig = {
          environments = defaultEnvs // {
            PORT = "8080";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/audiobookshelf/config" "/config")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/audiobookshelf/metadata" "/metadata")
            (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/media/audiobooks" "/audiobooks")
            (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/media/podcasts" "/podcasts")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.audiobookshelf.portStr}:8080" ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requisiteAfter [
          "zfs.target"
        ];
      };

      shelfmark = {
        wantsCaddy = true;
        useGlobalContainers = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = defaultEnvs // {
            inherit (containerLib.containerIds) PUID PGID;
            UMASK = "002"; # 664 for files, 775 for dirs

            HIDE_LOCAL_AUTH = "true";
            SESSION_COOKIE_SECURE = "true";

            BOOK_LANGUAGE = "en,ru,uk";
            SEARCH_MODE = "universal";
            DEFAULT_RELEASE_SOURCE = "prowlarr";

            AUDIOBOOK_LIBRARY_URL = networkingLib.mkUrl "audiobookshelf";
            DESTINATION_AUDIOBOOK = "/data/media/audiobooks";
            HARDLINK_TORRENTS_AUDIOBOOK = "true";
            FILE_ORGANIZATION_AUDIOBOOK = "organize";
            TEMPLATE_AUDIOBOOK_ORGANIZE = "{Author}/{Series/}{SeriesPosition - }{Title}/{PartNumber - }{Title}";

            HARDCOVER_ENABLED = "true";
            OPENLIBRARY_ENABLED = "true";

            PROWLARR_ENABLED = "true";
            PROWLARR_URL = "prowlarr:9696";

            PROWLARR_TORRENT_CLIENT = "qbittorrent";
            QBITTORRENT_URL = "gluetun:8080";
            QBITTORRENT_CATEGORY_AUDIOBOOK = "audiobooks";

            PROWLARR_USENET_CLIENT = "sabnzbd";
            SABNZBD_URL = "sabnzbd:8080";
            SABNZBD_CATEGORY_AUDIOBOOK = "audiobooks";
            PROWLARR_USENET_ACTION = "move";
          };
          environmentFiles = [ config.sops.secrets."data-library/shelfmark.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/shelfmark/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia externalStoreRoot "/data")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.shelfmark.portStr}:8084" ];
          inherit networks;
        };

        unitConfig = lib.mkMerge [
          afterDownloaders
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };
    };
  };
}
