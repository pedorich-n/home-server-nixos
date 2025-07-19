{ config, containerLib, systemdLib, networkingLib, ... }:
let
  networks = [ "data-library-internal.network" ];

  mkApiSecureTraefikLabels = name: containerLib.mkTraefikLabels {
    name = "${name}-secure-api";
    rule = "Host(`${networkingLib.mkDomain name}`) && PathPrefix(`/api/`)";
    service = "${name}-secure";
    entrypoints = [ "web-secure" ];
    priority = 15;
  };

  defaultEnvs = {
    TZ = "${config.time.timeZone}";
  };

  storeRoot = "/mnt/store/data-library";
  externalStoreRoot = "/mnt/external/data-library";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

  afterDownloaders = {
    After = [
      "qbittorrent.service"
      "sabnzbd.service"
      "gluetun.service"
    ];
  };
in
{
  custom.networking.ports.udp = {
    jellyfin-service-discovery = { port = 1900; openFirewall = true; };
    jellyfin-client-discovery = { port = 7359; openFirewall = true; };
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
            DOT = "off";

            VPN_TYPE = "wireguard";
            SERVER_COUNTRIES = "Japan,Korea";
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_PORT_FORWARDING = "on";
            VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
            VPN_PORT_FORWARDING_UP_COMMAND = "/gluetun/scripts/qbt_update_port_forward.sh {{PORTS}}";

            # OPENVPN_FLAGS = "--tun-mtu 1400";
            # OPENVPN_MSSFIX = "1300";
            # OPENVPN_VERBOSITY = "4";
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
            "${./gluetun/qbt_update_port_forward.sh}:/gluetun/scripts/qbt_update_port_forward.sh"
            "${./gluetun/auth_config.toml}:/gluetun/auth/config.toml"
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "qbittorrent-secure"; # Proxied
            port = 8080;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++ (mkApiSecureTraefikLabels "qbittorrent");
          inherit networks;
        };
      };

      qbittorrent = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (mappedVolumeForUser "${storeRoot}/qbittorrent/config" "/config")
            (mappedVolumeForUser "${externalStoreRoot}/downloads/torrent" "/data/downloads/torrent")
            "${./qbittorrent/auto_unrar.sh}:/opt/scripts/auto_unrar.sh"
          ];
          networks = [ "gluetun.container" ];
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.bindsToAfter [ "gluetun.service" ];
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
            (mappedVolumeForUser "${storeRoot}/sabnzbd/config" "/config")
            (mappedVolumeForUser "${externalStoreRoot}/downloads/usenet" "/data/downloads/usenet")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "sabnzbd-secure";
            port = environments.PORT;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++ (mkApiSecureTraefikLabels "sabnzbd");
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      prowlarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (mappedVolumeForUser "${storeRoot}/prowlarr/config" "/config")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "prowlarr-secure";
            port = 9696;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++ (mkApiSecureTraefikLabels "prowlarr");
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
            (mappedVolumeForUser "${storeRoot}/sonarr/config" "/config")
            (mappedVolumeForUser externalStoreRoot "/data")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "sonarr-secure";
            port = 8989;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++ (mkApiSecureTraefikLabels "sonarr");
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = afterDownloaders;
      };

      radarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          volumes = [
            (mappedVolumeForUser "${storeRoot}/radarr/config" "/config")
            (mappedVolumeForUser externalStoreRoot "/data")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "radarr-secure";
            port = 7878;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++ (mkApiSecureTraefikLabels "radarr");
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = afterDownloaders;
      };

      jellyfin = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
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
            (mappedVolumeForUser "${storeRoot}/jellyfin/config" "/config")
            (mappedVolumeForUser "${storeRoot}/jellyfin/cache" "/cache")
            (mappedVolumeForUser "${externalStoreRoot}/media" "/media")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "jellyfin-secure";
            port = 8096;
            entrypoints = [ "web-secure" ];
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
      };

      audiobookshelf = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs // {
            PORT = "8080";
          };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/audiobookshelf/config" "/config")
            (mappedVolumeForUser "${storeRoot}/audiobookshelf/metadata" "/metadata")
            (mappedVolumeForUser "${externalStoreRoot}/media/audiobooks" "/audiobooks")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "audiobookshelf-secure";
            port = 8080;
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };
    };
  };
}
