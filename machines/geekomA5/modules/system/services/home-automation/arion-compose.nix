{ config, pkgs, dockerLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeFor = localPath: remotePath: "/mnt/store/home-automation/${localPath}:${remotePath}";

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    mosquitto = ./mosquitto/_config.nix;
  };
in
{
  virtualisation.arion.projects = {
    home-automation.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "home-automation") // dockerLib.externalTraefikNetwork;

      services = {
        # Home Automation
        mariadb.service = {
          image = "mariadb:${containerVersions.homeassistant-mariadb}";
          container_name = "mariadb";
          restart = "unless-stopped";
          environment = {
            MARIADB_ROOT_PASSWORD_FILE = "/var/lib/mysql/root_password";
            MARIADB_DATABASE = "ha_database";
            MARIADB_USER_FILE = "/var/lib/mysql/user";
            MARIAD_PASSWORD_FILE = "/var/lib/mysql/password";
            TZ = "${config.time.timeZone}";
          };
          user = userSetting;
          volumes = [
            (storeFor "mariadb" "/var/lib/mysql")
            "${config.age.secrets.mariadb_root_password.path}:/var/lib/mysql/root_password:ro"
            "${config.age.secrets.mariadb_user.path}:/var/lib/mysql/user:ro"
            "${config.age.secrets.mariadb_password.path}:/var/lib/mysql/password:ro"
          ];
          networks = [ "default" ];
        };

        mosquitto.service = {
          image = "eclipse-mosquitto:${containerVersions.mosquitto}";
          container_name = "mosquitto";
          restart = "unless-stopped";
          volumes = [
            "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
            "${config.age.secrets.mosquitto_passwords_hashed.path}:/mosquitto/config/passwords.txt:ro"
            (storeFor "mosquitto/data" "/mosquitto/data")
            (storeFor "mosquitto/log" "/mosquitto/log")
          ];
          networks = [ "default" "traefik" ];
          user = userSetting;
          labels = {
            "traefik.enable" = "true";
            "traefik.tcp.routers.mosquitto.rule" = "HostSNI(`*`)";
            "traefik.tcp.routers.mosquitto.entrypoints" = "mqtt";
            "traefik.tcp.routers.mosquitto.service" = "mosquitto";
            "traefik.tcp.services.mosquitto.loadBalancer.server.port" = "1883";
          };
        };

        zigbee2mqtt.service = rec {
          image = "koenkk/zigbee2mqtt:${containerVersions.zigbee2mqtt}";
          container_name = "zigbee2mqtt";
          restart = "unless-stopped";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            # configuration file is managed by systemd.tmpfiles
            (storeFor "zigbee2mqtt" "/app/data")
            "${config.age.secrets.zigbee2mqtt_secrets.path}:/app/data/secrets.yaml:ro"
            "/run/udev:/run/udev:ro"
          ];
          devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
          depends_on = [ "mosquitto" ];
          networks = [ "default" "traefik" ];
          # user = userSetting;
          labels = dockerLib.mkTraefikLabels {
            name = container_name;
            port = 8080;
            middlewares = [ "authentik@docker" ];
          };
        };

        nodered.service = rec {
          image = "nodered/node-red:${containerVersions.nodered}";
          container_name = "nodered";
          environment = {
            TZ = "${config.time.timeZone}";
            NODE_RED_ENABLE_PROJECTS = "true";
          };
          restart = "unless-stopped";
          networks = [ "traefik" "default" ];
          user = userSetting;
          volumes = [
            (storeFor "nodered" "/data")
          ];
          labels = (dockerLib.mkTraefikLabels {
            name = container_name;
            port = 1880;
            priority = 10;
            middlewares = [ "authentik@docker" ];
          }) //
          (dockerLib.mkTraefikLabels {
            name = "${container_name}-hooks";
            rule = "Host(`${container_name}.${config.custom.networking.domain}`) && PathPrefix(`/hooks/`)";
            service = container_name;
            priority = 15;
          });
        };

        homeassistant.service = rec {
          image = "homeassistant/home-assistant:2024.7.4"; # Not all integrations are ready for the 2024.8.X :(
          container_name = "homeassistant";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          restart = "unless-stopped";
          networks = [ "default" "traefik" ];
          # user = userSetting;
          capabilities = {
            CAP_NET_RAW = true;
            CAP_NET_BIND_SERVICE = true;
          };
          volumes = [
            (storeFor "homeassistant" "/config")
            (storeFor "homeassistant/local" "/.local")
            "${config.age.secrets.ha_secrets.path}:/config/secrets.yaml"
          ];
          labels = dockerLib.mkTraefikLabels {
            name = container_name;
            port = 80;
            middlewares = [ "authentik@docker" ];
          };
          depends_on = [
            "mariadb"
            "mosquitto"
          ];
        };
      };
    };
  };
}
