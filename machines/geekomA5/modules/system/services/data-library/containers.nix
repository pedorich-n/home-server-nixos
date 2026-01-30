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

  mkApiSecureTraefikLabels =
    name:
    containerLib.mkTraefikLabels {
      name = "${name}-api";
      traefikName = "${name}-api-secure";
      rule = "Host(`${networkingLib.mkDomain name}`) && PathPrefix(`/api`)";
      service = "${name}-secure";
      entrypoints = [ "web-secure" ];
      priority = 15;
    };

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
in
{
  custom.networking.ports.udp = {
    jellyfin-service-discovery = {
      port = 1900;
      openFirewall = true;
    };
    jellyfin-client-discovery = {
      port = 7359;
      openFirewall = true;
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "data-library";

    containers = {
      gluetun = {
        requiresTraefikNetwork = true;
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
          labels =
            (containerLib.mkTraefikLabels {
              name = "qbittorrent"; # Proxied
              port = 8080;
              priority = 10;
              middlewares = [ "authelia@file" ];
            })
            ++ (mkApiSecureTraefikLabels "qbittorrent");
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
        requiresTraefikNetwork = true;
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
          labels =
            (containerLib.mkTraefikLabels {
              name = "sabnzbd";
              port = environments.PORT;
              priority = 10;
              middlewares = [ "authelia@file" ];
            })
            ++ (mkApiSecureTraefikLabels "sabnzbd");
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requisiteAfter [
          "zfs.target"
        ];
      };

      prowlarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/prowlarr/config" "/config")
          ];
          labels =
            (containerLib.mkTraefikLabels {
              name = "prowlarr";
              port = 9696;
              priority = 10;
              middlewares = [ "authelia@file" ];
            })
            ++ (mkApiSecureTraefikLabels "prowlarr");
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = afterDownloaders;
      };

      sonarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/sonarr/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia externalStoreRoot "/data")
          ];
          labels =
            (containerLib.mkTraefikLabels {
              name = "sonarr";
              port = 8989;
              priority = 10;
              middlewares = [ "authelia@file" ];
            })
            ++ (mkApiSecureTraefikLabels "sonarr");
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
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/radarr/config" "/config")
            (containerLib.mkMappedVolumeForUserMedia externalStoreRoot "/data")
          ];
          labels =
            (containerLib.mkTraefikLabels {
              name = "radarr";
              port = 7878;
              priority = 10;
              middlewares = [ "authelia@file" ];
            })
            ++ (mkApiSecureTraefikLabels "radarr");
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

      recyclarr = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs // {
            CRON_SCHEDULE = "0 6 * * *"; # Run daily at 6 AM
          };
          environmentFiles = [
            config.sops.secrets."data-library/recyclarr.env".path
          ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/recyclarr/config" "/config")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.sonarr.ref
          containers.radarr.ref
        ];
      };

      jellyfin = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          notify = "healthy"; # This image has working healthcheck already, so I just need to connect it to systemd
          addGroups = [
            (builtins.toString config.users.groups.render.gid) # For HW Transcoding
          ];
          # publishPorts = [
          #   "1900:1900/udp"
          #   "7359:7359/udp"
          # ];
          devices = [
            # HW Transcoding acceleration.
            # See https://jellyfin.org/docs/general/installation/container#with-hardware-acceleration
            # See https://jellyfin.org/docs/general/administration/hardware-acceleration/amd#linux-setups
            "/dev/dri:/dev/dri"
          ];
          environments = defaultEnvs // {
            JELLYFIN_PublishedServerUrl = networkingLib.mkUrl "jellyfin";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/jellyfin/config" "/config")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/jellyfin/cache" "/cache")
            (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/media" "/media")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "jellyfin";
            port = 8096;
          };
          #  ++ [
          #   "traefik.udp.services.jellyfin-service-discovery.loadBalancer.server.port=1900"
          #   "traefik.udp.routers.jellyfin-service-discovery.entrypoints=jellyfin-service-discovery"
          #   "traefik.udp.routers.jellyfin-service-discovery.service=jellyfin-service-discovery"

          #   "traefik.udp.services.jellyfin-client-discovery.loadBalancer.server.port=7359"
          #   "traefik.udp.routers.jellyfin-client-discovery.entrypoints=jellyfin-client-discovery"
          #   "traefik.udp.routers.jellyfin-client-discovery.service=jellyfin-client-discovery"
          # ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requisiteAfter [
          "zfs.target"
        ];
      };

      audiobookshelf = {
        requiresTraefikNetwork = true;
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
          labels = containerLib.mkTraefikLabels {
            name = "audiobookshelf";
            port = 8080;
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requisiteAfter [
          "zfs.target"
        ];
      };

      shelfmark = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = false;
          size = containerLib.containerIds.uid + 500;
        };

        containerConfig = {
          environments = defaultEnvs // {
            # inherit (containerLib.containerIds) PUID PGID;
            PUID = toString config.users.users.user.uid;
            PGID = toString config.users.groups.media.gid;
            UMASK = "007";

            SESSION_COOKIE_SECURE = "true";
            BOOK_LANGUAGE = "en,ru,uk";

            AUDIOBOOK_LIBRARY_URL = networkingLib.mkUrl "audiobookshelf";

            SEARCH_MODE = "universal";
            DEFAULT_RELEASE_SOURCE = "prowlarr";

            DESTINATION_AUDIOBOOK = "/data/media/audiobooks";
            HARDLINK_TORRENTS_AUDIOBOOK = "true";
            FILE_ORGANIZATION_AUDIOBOOK = "organize";
            TEMPLATE_AUDIOBOOK_ORGANIZE = "{Author}/{Series}/{SeriesPosition - }{Title}/{Title}";

            HARDCOVER_ENABLED = "true";

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
            # (containerLib.mkMappedVolumeForUser "${storeRoot}/shelfmark/config" "/config")
            # (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/media/audiobooks" "/data/media/audiobooks")
            # (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/downloads/torrent" "/data/downloads/torrent")
            # (containerLib.mkMappedVolumeForUserMedia "${externalStoreRoot}/downloads/usenet" "/data/downloads/usenet")
            "${storeRoot}/shelfmark/config:/config"
            "${externalStoreRoot}/media/audiobooks:/data/media/audiobooks"
            "${externalStoreRoot}/downloads/torrent:/data/downloads/torrent"
            "${externalStoreRoot}/downloads/usenet:/data/downloads/usenet"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "shelfmark";
            port = 8084;
            middlewares = [ "authelia@file" ];
          };
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
