{ config, pkgs, containerLib, systemdLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeFor = localPath: remotePath: "/mnt/store/home-automation/${localPath}:${remotePath}";

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    mosquitto = ./mosquitto/_config.nix;
  };

  withInternalNetwork = containerLib.mkWithNetwork "home-automation-internal";
in
{
  systemd.targets.home-automation = {
    wants = [
      "home-automation-internal-network.service"
      "homeassistant.service"
      "homeassistant-postgresql.service"
      "zigbeemqtt.service"
      "nodered.service"
      "mosquitto.service"
    ];
  };

  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "home-automation";

    containers = {
      mosquitto = withInternalNetwork {
        requiresTraefikNetwork = true;

        containerConfig = {
          image = "eclipse-mosquitto:${containerVersions.mosquitto}";
          name = "mosquitto";
          volumes = [
            "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
            "${config.age.secrets.mosquitto_passwords.path}:/mosquitto/config/passwords.txt:ro"
            (storeFor "mosquitto/data" "/mosquitto/data")
            (storeFor "mosquitto/log" "/mosquitto/log")
          ];
          user = userSetting;
          labels = [
            "traefik.enable=true"
            "traefik.tcp.routers.mosquitto.rule=HostSNI(`*`)"
            "traefik.tcp.routers.mosquitto.entrypoints=mqtt"
            "traefik.tcp.routers.mosquitto.service=mosquitto"
            "traefik.tcp.services.mosquitto.loadBalancer.server.port=1883"
          ];
        };
      };

      zigbee2mqtt = withInternalNetwork {
        requiresTraefikNetwork = true;

        containerConfig = rec {
          image = "koenkk/zigbee2mqtt:${containerVersions.zigbee2mqtt}";
          name = "zigbee2mqtt";
          environments = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            # configuration file is managed by systemd.tmpfiles
            (storeFor "zigbee2mqtt" "/app/data")
            "${config.age.secrets.zigbee2mqtt_secrets.path}:/app/data/secrets.yaml:ro"
            "/run/udev:/run/udev:ro"
          ];
          devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
          # user = userSetting;
          labels = containerLib.mkTraefikLabels {
            inherit name;
            port = 8080;
            middlewares = [ "authentik@docker" ];
          };
        };

        unitConfig = systemdLib.requiresAfter [ "mosquitto.service" ] { };
      };

      homeassistant-postgresql = withInternalNetwork {
        containerConfig = {
          image = "docker.io/library/postgres:${containerVersions.homeassistant-postgresql}";
          name = "homeassistant-postgresql";
          environmentFiles = [ config.age.secrets.ha_postgres.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
        };
      };

      homeassistant = withInternalNetwork {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;

        containerConfig = rec {
          image = "homeassistant/home-assistant:${containerVersions.homeassistant}";
          name = "homeassistant";
          environments = {
            TZ = "${config.time.timeZone}";
          };
          # user = userSetting;
          # capabilities = {
          #   CAP_NET_RAW = true;
          #   CAP_NET_BIND_SERVICE = true;
          # };
          volumes = [
            (storeFor "homeassistant" "/config")
            (storeFor "homeassistant/local" "/.local")
            "${config.age.secrets.ha_secrets.path}:/config/secrets.yaml"
          ];
          labels = (containerLib.mkTraefikLabels {
            inherit name;
            port = 80;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) ++
          (containerLib.mkTraefikLabels {
            name = "${name}-hooks";
            rule = "Host(`${name}.${config.custom.networking.domain}`) && PathPrefix(`/api/webhook/`)";
            service = name;
            priority = 15;
          });
        };

        unitConfig = systemdLib.requiresAfter
          [
            "homeassistant-postgresql.service"
            "mosquitto.service"
          ]
          { };
      };

      nodered = withInternalNetwork {
        requiresTraefikNetwork = true;
        wantsAuthentik = true;

        containerConfig = rec {
          image = "nodered/node-red:${containerVersions.nodered}";
          name = "nodered";
          environments = {
            TZ = "${config.time.timeZone}";
            NODE_RED_ENABLE_PROJECTS = "true";
          };
          user = userSetting;
          volumes = [
            (storeFor "nodered" "/data")
          ];
          labels = containerLib.mkTraefikLabels {
            inherit name;
            port = 1880;
            middlewares = [ "authentik@docker" ];
          };
        };
      };

    };
  };
}
