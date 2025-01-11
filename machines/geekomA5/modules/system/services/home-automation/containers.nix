{ inputs, config, pkgs, containerLib, systemdLib, ... }:
let
  storeRoot = "/mnt/store/home-automation";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    mosquitto = ./mosquitto/_config.nix;
  };

  networks = [ "home-automation-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "home-automation";

    containers = {
      mosquitto = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          volumes = [
            "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
            "${config.age.secrets.mosquitto_passwords.path}:/mosquitto/config/passwords.txt:ro"
            (mappedVolumeForUser "${storeRoot}/mosquitto/data" "/mosquitto/data")
            (mappedVolumeForUser "${storeRoot}/mosquitto/log" "/mosquitto/log")
          ];
          labels = [
            "traefik.enable=true"
            "traefik.tcp.routers.mosquitto.rule=HostSNI(`*`)"
            "traefik.tcp.routers.mosquitto.entrypoints=mqtt"
            "traefik.tcp.routers.mosquitto.service=mosquitto"
            "traefik.tcp.services.mosquitto.loadBalancer.server.port=1883"
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      zigbee2mqtt = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/zigbee2mqtt" "/app/data")
            "${config.age.secrets.zigbee2mqtt_secrets.path}:/app/data/secrets.yaml:ro"
            "/run/udev:/run/udev:ro"
          ];
          addGroups = [
            (builtins.toString config.users.groups.zigbee.gid)
          ];
          devices = [
            "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0:/dev/ttyZigbee"
          ];
          labels = containerLib.mkTraefikLabels {
            name = "zigbee2mqtt";
            port = 8080;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [ "mosquitto.service" ] { };
      };

      homeassistant-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.age.secrets.ha_postgres.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      homeassistant = {
        useGlobalContainers = true;
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
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
          # capabilities = {
          #   CAP_NET_RAW = true;
          #   CAP_NET_BIND_SERVICE = true;
          # };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/homeassistant" "/config")
            (mappedVolumeForUser "${storeRoot}/homeassistant/local" "/.local")
            "${config.age.secrets.ha_secrets.path}:/config/secrets.yaml"
            # See https://github.com/tribut/homeassistant-docker-venv
            "${inputs.homeassistant-docker-venv}/run:/etc/services.d/home-assistant/run"
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "homeassistant";
            port = 8123;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) ++
          (containerLib.mkTraefikLabels {
            name = "homeassistant-hooks";
            rule = "'Host(`homeassistant.${config.custom.networking.domain}`) && PathPrefix(`/api/webhook/`)'";
            service = "homeassistant";
            priority = 15;
          });
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "homeassistant-postgresql.service"
            "mosquitto.service"
          ]
          { };
      };

      nodered = {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;
        useGlobalContainers = true;
        usernsAuto.enable = true;
        autoStart = false;

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
            NODE_RED_ENABLE_PROJECTS = "true";
          };
          volumes = [
            (mappedVolumeForUser "${storeRoot}/nodered" "/data")
          ];
          labels = containerLib.mkTraefikLabels {
            name = "nodered";
            port = 1880;
            middlewares = [ "authentik@docker" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

    };
  };
}
