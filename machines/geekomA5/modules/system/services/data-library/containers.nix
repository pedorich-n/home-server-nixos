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

    # TODO: auth
    containers = {
      nzbget = {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "ghcr.io/nzbgetcom/nzbget:${containerVersions.nzbget}";
          name = "nzbget";
          environments = {
            TZ = "${config.time.timeZone}";
            PIUD = "1000";
            PGID = "1000";
          };
          volumes = [
            (storeFor "nzbget/config" "/config")
            (externalStoreFor "downloads/usenet" "/data/downloads/usenet")
          ];
          labels = containerLib.mkTraefikLabels { name = "nzbget"; port = 6789; };
          inherit networks pod;
        };
      };

      # TODO: auth
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
          labels = containerLib.mkTraefikLabels { name = "prowlarr"; port = 9696; };
          inherit networks pod;
        };
      };

      # TODO: auth
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
          labels = containerLib.mkTraefikLabels { name = "sonarr"; port = 8989; };
          inherit networks pod;
        };
      };

      # TODO: auth
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
          labels = containerLib.mkTraefikLabels { name = "radarr"; port = 7878; };
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
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthRetries = 5;
          notify = "healthy";
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
          labels = containerLib.mkTraefikLabels { name = "jellyfin"; port = 8096; };
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
