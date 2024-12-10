{ config, containerLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/data-library/${localPath}:${remotePath}";
  externalStoreFor = localPath: remotePath: "/mnt/external/data-library/${localPath}:${remotePath}";

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
          };
          volumes = [
            (storeFor "nzbget/config" "/config")
            (externalStoreFor "downloads/usenet" "/downloads")
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
          };
          volumes = [
            (storeFor "prowlarr/config" "/config")
          ];
          labels = containerLib.mkTraefikLabels { name = "prowlarr"; port = 9696; };
          inherit networks pod;
        };
      };
    };
  };
}
