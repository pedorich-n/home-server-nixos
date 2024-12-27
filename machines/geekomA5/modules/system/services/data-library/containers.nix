{ config, lib, containerLib, systemdLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/data-library/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: ''/mnt/external/data-library${if (localPath != "") then "/${localPath}" else ""}:${remotePath}'';

  pod = "data-library.pod";
  networks = [ "data-library-internal.network" ];

  mkArrApiTraefikLabels = name: containerLib.mkTraefikLabels {
    name = "${name}-api";
    rule = "'Host(`${name}.${config.custom.networking.domain}`) && PathPrefix(`/api/`)'";
    service = name;
    priority = 15;
  };
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "data-library";

    pods.data-library = {
      podConfig = { inherit networks; };
    };

    containers = {
      gluetun = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          environments = {
            VPN_SERVICE_PROVIDER = "nordvpn";
            SERVER_COUNTRIES = "Japan";
          };
          environmentFiles = [ config.age.secrets.gluetun.path ];
          # https://github.com/qdm12/gluetun/blob/ddd9f4d0210c35d062896ffa2c7dc6e585deddfb/Dockerfile#L226
          healthCmd = "/gluetun-entrypoint healthcheck";
          healthStartPeriod = "10s";
          healthTimeout = "5s";
          healthInterval = "5s";
          healthRetries = 5;
          notify = "healthy";
          labels = containerLib.mkTraefikLabels {
            name = "qbittorrent"; # Proxied
            port = 8080;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };

        serviceConfig = {
          Environment = [
            ''PATH=${lib.makeBinPath [ "/run/wrappers" config.systemd.package ]}''
          ];
        };
      };

      qbittorrent = {
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            PUID = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "qbittorrent/config" "/config")
            (externalStoreFor "downloads/torrent" "/data/downloads/torrent")
          ];
          # Broken until https://github.com/containers/podman/pull/24794 is released
          # networks = [ "gluetun.container" ];
          networks = [ "container:gluetun" ];
          inherit pod;
        };

        unitConfig = systemdLib.requiresAfter [ "gluetun.service" ] { };
      };

      sabnzbd = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            PUID = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "sabnzbd/config" "/config")
            (externalStoreFor "downloads/usenet" "/data/downloads/usenet")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "sabnzbd";
            port = 8080;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };

      prowlarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "prowlarr/config" "/config")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "prowlarr";
            port = 9696;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) ++ (mkArrApiTraefikLabels "prowlarr");
          inherit networks pod;
        };
      };

      sonarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "sonarr/config" "/config")
            (externalStoreFor "" "/data")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "sonarr";
            port = 8989;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) ++ (mkArrApiTraefikLabels "sonarr");
          inherit networks pod;
        };
      };

      radarr = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "radarr/config" "/config")
            (externalStoreFor "" "/data")
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "radarr";
            port = 7878;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) ++ (mkArrApiTraefikLabels "radarr");
          inherit networks pod;
        };
      };

      jellyfin = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
          };
          notify = "healthy"; # This image has working healthcheck already, so I just need to connect it to systemd
          user = "1000:1000";
          devices = [
            # HW Transcoding acceleration. 
            # See https://jellyfin.org/docs/general/installation/container#with-hardware-acceleration
            # See https://jellyfin.org/docs/general/administration/hardware-acceleration/amd#linux-setups
            "/dev/dri:/dev/dri"
          ];
          environments = {
            JELLYFIN_PublishedServerUrl = "http://jellyfin.${config.custom.networking.domain}";
          };
          volumes = [
            (storeFor "jellyfin/config" "/config")
            (storeFor "jellyfin/cache" "/cache")
            (externalStoreFor "media" "/media")
          ];
          labels = (containerLib.mkTraefikLabels { name = "jellyfin"; port = 8096; }) ++ [
            "traefik.udp.services.jellyfin-service-discovery.loadBalancer.server.port=1900"
            "traefik.udp.routers.jellyfin-service-discovery.entrypoints=jellyfin-service-discovery"
            "traefik.udp.routers.jellyfin-service-discovery.service=jellyfin-service-discovery"

            "traefik.udp.services.jellyfin-client-discovery.loadBalancer.server.port=7359"
            "traefik.udp.routers.jellyfin-client-discovery.entrypoints=jellyfin-client-discovery"
            "traefik.udp.routers.jellyfin-client-discovery.service=jellyfin-client-discovery"
          ];
          inherit networks pod;
        };

        serviceConfig = {
          Environment = [
            ''PATH=${lib.makeBinPath [ "/run/wrappers" config.systemd.package ]}''
          ];
        };
      };
    };
  };
}
