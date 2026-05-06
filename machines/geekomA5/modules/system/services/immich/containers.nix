{
  config,
  containerLib,
  systemdLib,
  lib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
  portsCfg = config.custom.networking.ports.tcp;

  storeRoot = "/mnt/store/immich";
  externalStoreRoot = "/mnt/external/immich-library";

  sharedEnvs = {
    # https://immich.app/docs/install/environment-variables/
    TZ = "${config.time.timeZone}";
    REDIS_HOSTNAME = "immich-valkey";
    DB_HOSTNAME = "immich-postgresql";

  };

  networks = [ "immich-internal.network" ];

  mkMappedVolumeForUserContainerRoot =
    hostPath: containerPath:
    containerLib.mkIdMappedVolume {
      inherit hostPath containerPath;
      uidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
in
{
  custom.networking.ports.tcp = {
    immich-metrics = {
      port = 20081;
      openFirewall = false;
    };
    immich-microservices-metrics = {
      port = 20082;
      openFirewall = false;
    };
  };

  custom.services.caddy.metrics.routes = {
    immich = {
      url = "http://localhost:${portsCfg.immich-metrics.portStr}";
    };
    immich-microservices = {
      url = "http://localhost:${portsCfg.immich-microservices-metrics.portStr}";
    };
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "immich";

    containers = {
      immich-postgresql = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          environments = sharedEnvs;
          environmentFiles = [ config.sops.secrets."immich/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          shmSize = "128m";
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      immich-valkey = {
        usernsAuto.enable = true;
        useGlobalContainers = true;

        containerConfig = {
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      immich-machine-learning = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          volumes = [
            # Looks like this container doesn't work properly with both `user` and `userns` set.
            # It spits "permission denied" errors when it tries to write to download ML models.
            # So I'll just leave it running as root inside the container and map volume for root.
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/machine-learning/model-cache" "/cache")
          ];
          inherit networks;
          # inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.immich-valkey.ref
          containers.immich-postgresql.ref
        ];
      };

      immich-server = {
        requiresTraefikNetwork = true;
        wantsAuthelia = true;
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = sharedEnvs // {
            # See https://immich.app/docs/features/monitoring#prometheus
            IMMICH_TELEMETRY_INCLUDE = "all";
            # See https://docs.immich.app/install/environment-variables#general
            IMMICH_API_METRICS_PORT = portsCfg.immich-metrics.portStr;
            IMMICH_MICROSERVICES_METRICS_PORT = portsCfg.immich-microservices-metrics.portStr;
          };
          environmentFiles = [ config.sops.secrets."immich/main.env".path ];
          addGroups = [
            (builtins.toString config.users.groups.render.gid) # For HW Transcoding
          ];
          devices = [
            "/dev/dri:/dev/dri" # HW Transcoding acceleration. See https://immich.app/docs/features/hardware-transcoding
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            (containerLib.mkMappedVolumeForUser "${storeRoot}/cache/thumbnails" "/data/thumbs")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/cache/profile" "/data/profile")
            (containerLib.mkMappedVolumeForUser externalStoreRoot "/data")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "immich";
            port = 2283;
          };
          publishPorts = [
            "127.0.0.1:${portsCfg.immich-metrics.portStr}:${portsCfg.immich-metrics.portStr}"
            "127.0.0.1:${portsCfg.immich-microservices-metrics.portStr}:${portsCfg.immich-microservices-metrics.portStr}"
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            containers.immich-valkey.ref
            containers.immich-postgresql.ref
          ])
          (systemdLib.requisiteAfter [
            "zfs.target"
          ])
        ];
      };
    };

  };

}
