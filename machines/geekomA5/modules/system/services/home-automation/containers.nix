{
  inputs,
  config,
  lib,
  containerLib,
  systemdLib,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;

  storeRoot = "/mnt/store/home-automation";

  # configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
  #   mosquitto = ./mosquitto/_config.nix;
  # };

  networks = [ "home-automation-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "home-automation";

    containers = {
      # mosquitto = {
      #   requiresTraefikNetwork = true;
      #   useGlobalContainers = true;
      #   usernsAuto.enable = true;

      #   containerConfig = {
      #     volumes = [
      #       "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
      #       (containerLib.mkMappedVolumeForUser config.sops.secrets."home-automation/mosquitto_passwords.txt".path "/mosquitto/config/passwords.txt")
      #       (containerLib.mkMappedVolumeForUser "${storeRoot}/mosquitto/data" "/mosquitto/data")
      #       (containerLib.mkMappedVolumeForUser "${storeRoot}/mosquitto/log" "/mosquitto/log")
      #     ];
      #     labels = [
      #       "traefik.enable=true"
      #       "traefik.tcp.routers.mosquitto.rule=HostSNI(`*`)"
      #       "traefik.tcp.routers.mosquitto.entrypoints=mqtt"
      #       "traefik.tcp.routers.mosquitto.service=mosquitto"
      #       "traefik.tcp.services.mosquitto.loadBalancer.server.port=1883"
      #     ];
      #     inherit networks;
      #     inherit (containerLib.containerIds) user;
      #   };
      # };

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
            (builtins.toString config.users.groups.zigbee.gid)
          ];
          devices = [
            "/dev/ttyZigbee:/dev/ttyZigbee"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "zigbee2mqtt-secure";
            port = 8080;
            middlewares = [ "authelia@file" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          # (systemdLib.requiresAfter [ containers.mosquitto.ref ])
          (systemdLib.bindsToAfter [ "dev-ttyZigbee.device" ])
        ];
      };

      homeassistant-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."home-automation/postgresql.env".path ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
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
            inherit (containerLib.containerIds) PUID PGID;
            UMASK = "007";
          };
          addCapabilities = [ "NET_RAW" ];
          volumes = [
            (containerLib.mkMappedVolumeForUser "${storeRoot}/homeassistant" "/config")
            (containerLib.mkMappedVolumeForUser "${storeRoot}/homeassistant/local" "/.local")
            (containerLib.mkMappedVolumeForUser config.sops.secrets."home-automation/homeassistant_secrets.yaml".path "/config/secrets.yaml")
            # See https://github.com/tribut/homeassistant-docker-venv
            "${inputs.homeassistant-docker-venv}/run:/etc/services.d/home-assistant/run"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "homeassistant-secure";
            port = 8123;
            priority = 10;
          };
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter [
          containers.homeassistant-postgresql.ref
          # containers.mosquitto.ref
        ];
      };

    };
  };
}
