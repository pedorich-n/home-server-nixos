{ config, lib, containerLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/data-library/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: ''/mnt/external/data-library${if (localPath != "") then "/${localPath}" else ""}:${remotePath}'';

  pod = "data-library.pod";
  networks = [ "data-library-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "data-library";

    pods.data-library = {
      podConfig = { inherit networks; };
    };

    containers = {
      sabnzbd = {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "lscr.io/linuxserver/sabnzbd:${containerVersions.sabnzbd}";
          name = "sabnzbd";
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

        containerConfig = {
          image = "ghcr.io/hotio/prowlarr:${containerVersions.prowlarr}";
          name = "prowlarr";
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "prowlarr/config" "/config")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "prowlarr";
            port = 9696;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };

      sonarr = {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "ghcr.io/hotio/sonarr:${containerVersions.sonarr}";
          name = "sonarr";
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "sonarr/config" "/config")
            (externalStoreFor "" "/data")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "sonarr";
            port = 8989;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };

      radarr = {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "ghcr.io/hotio/radarr:${containerVersions.radarr}";
          name = "radarr";
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "radarr/config" "/config")
            (externalStoreFor "" "/data")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "radarr";
            port = 7878;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks pod;
        };
      };

      jellyfin = {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "docker.io/jellyfin/jellyfin:${containerVersions.jellyfin}";
          name = "jellyfin";
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
