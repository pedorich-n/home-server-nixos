{
  config,
  lib,
  containerLib,
  systemdLib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/home-automation";

  networks = [ "home-automation-internal.network" ];

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
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "home-automation";

    containers = {
      zigbee2mqtt = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/zigbee2mqtt" "/app/data")
            (containerLib.mkMappedVolumeForUser config.sops.secrets."home-automation/zigbee2mqtt_secrets.yaml".path "/app/data/secrets.yaml")
          ];
          addGroups = [
            (toString config.users.groups.zigbee.gid)
          ];
          devices = [
            "/dev/ttyZigbee:/dev/ttyZigbee"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "zigbee2mqtt";
            port = 8080;
            middlewares = [ "authelia@file" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [ config.systemd.services.mosquitto.name ])
          (systemdLib.bindsToAfter [ "dev-ttyZigbee.device" ])
        ];
      };

      homeassistant-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."home-automation/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      homeassistant = {
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = true;
          size = containerLib.containerIds.uid + 500;
        };

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
          };
          addCapabilities = [ "NET_RAW" ];
          volumes = [
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/homeassistant" "/config")
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/homeassistant/local" "/.local")
            (mkMappedVolumeForUserContainerRoot config.sops.secrets."home-automation/homeassistant_secrets.yaml".path "/config/secrets.yaml")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "homeassistant";
            port = 8123;
            priority = 10;
          };
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.homeassistant-postgresql.ref
          config.systemd.services.mosquitto.name
        ];
      };

    };
  };
}
