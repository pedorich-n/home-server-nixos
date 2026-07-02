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
    containers.gluetun.ref
    config.systemd.services.sabnzbd.name
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
      shelfmark = {
        port = 31400;
        openFirewall = false;
      };
      audiobookshelf = {
        port = 31900;
        openFirewall = false;
      };
      mousehole = {
        port = 31300;
        openFirewall = false;
      };
    };

    services.caddy.hosts = {
      qbittorrent = {
        upstream = "http://127.0.0.1:${portsCfg.qbittorrent.portStr}";
        auth = "authelia";
        authBypassPaths = [ "/api*" ];
      };
      shelfmark = {
        upstream = "http://127.0.0.1:${portsCfg.shelfmark.portStr}";
      };
      audiobookshelf = {
        upstream = "http://127.0.0.1:${portsCfg.audiobookshelf.portStr}";
      };
      mousehole = {
        upstream = "http://127.0.0.1:${portsCfg.mousehole.portStr}";
        auth = "authelia";
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
            "127.0.0.1:${portsCfg.mousehole.portStr}:5010" # Mousehole Web UI
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
        autoStart = false; # New VPN seems to be using the same ASN every time, but better keep it running
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

      mousehole = {
        wantsCaddy = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;
        wantsAuthelia = true;

        containerConfig = {
          environments = defaultEnvs // {
            MOUSEHOLE_ALLOWED_ORIGINS = networkingLib.mkUrl "mousehole";
            MOUSEHOLE_ALLOWED_HOSTS = networkingLib.mkDomain "mousehole";
            MOUSEHOLE_INSECURE_ALLOW_NO_AUTH = "true"; # Use Authelia for authentication
            MOUSEHOLE_HTTPS_ONLY_COOKIES = "true";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/mousehole" "/var/lib/mousehole")
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

            # Sometimes it takes too long to go trough all permutations of
            # book, author, series names in different languages that search request times out.
            # So it's better to set it dynamically from the UI
            # BOOK_LANGUAGE = "en,ru,uk";
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
            PROWLARR_URL = networkingLib.mkUrl "prowlarr";

            PROWLARR_TORRENT_CLIENT = "qbittorrent";
            QBITTORRENT_URL = networkingLib.mkUrl "qbittorrent";
            QBITTORRENT_CATEGORY_AUDIOBOOK = "audiobooks";

            PROWLARR_USENET_CLIENT = "sabnzbd";
            SABNZBD_URL = networkingLib.mkUrl "sabnzbd";
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
