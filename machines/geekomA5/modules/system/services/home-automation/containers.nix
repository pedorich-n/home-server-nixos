{ inputs, config, lib, pkgs, containerLib, systemdLib, networkingLib, ... }:
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
            (mappedVolumeForUser config.sops.secrets."home-automation/mosquitto_passwords.txt".path "/mosquitto/config/passwords.txt")
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
            (mappedVolumeForUser config.sops.secrets."home-automation/zigbee2mqtt_secrets.yaml".path "/app/data/secrets.yaml")
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
            middlewares = [ "authentik-secure@docker" ];
          };
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [ "mosquitto.service" ])
          (systemdLib.bindsToAfter [ "dev-ttyZigbee.device" ])
        ];
      };

      homeassistant-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environmentFiles = [ config.sops.secrets."home-automation/postgresql.env".path ];
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
            (mappedVolumeForUser config.sops.secrets."home-automation/homeassistant_secrets.yaml".path "/config/secrets.yaml")
            # See https://github.com/tribut/homeassistant-docker-venv
            "${inputs.homeassistant-docker-venv}/run:/etc/services.d/home-assistant/run"
          ];
          labels = (containerLib.mkTraefikLabels {
            name = "homeassistant-secure";
            port = 8123;
            priority = 10;
            middlewares = [ "authentik-secure@docker" ];
          }) ++
          (containerLib.mkTraefikLabels {
            name = "homeassistant-secure-hooks";
            rule = "Host(`${networkingLib.mkDomain "homeassistant"}`) && PathPrefix(`/api/webhook/`)";
            service = "homeassistant-secure";
            priority = 15;
            entrypoints = [ "web-secure" ];
          });
          inherit networks;
        };

        unitConfig = systemdLib.requiresAfter [
          "homeassistant-postgresql.service"
          "mosquitto.service"
        ];
      };

    };
  };
}
