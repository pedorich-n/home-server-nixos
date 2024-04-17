{ config, pkgs, lib, customLib, ... }:
let
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeFor = localPath: remotePath: "/mnt/store/home-automation/${localPath}:${remotePath}";

  configs = builtins.mapAttrs (_: path: import path { inherit pkgs config lib; }) {
    mosquitto = ./mosquitto/_config.nix;
  };
in
{
  networking.firewall.interfaces."podman+" = {
    allowedUDPPorts = [ 53 5353 ];
    # allowedTCPPorts = [ 80 ];
  };

  systemd.services.arion-home-automation = {
    after = [ "network-online.target" "arion-server-management.service" ];
    # serviceConfig = {
    #   User = config.users.users.user.name;
    #   Group = config.users.users.user.group;
    # };
  };

  virtualisation.arion.projects = {
    home-automation.settings = {
      enableDefaultNetwork = false;

      networks = {
        default = {
          name = "internal-home-automation";
          internal = true;
        };
        traefik = {
          name = "traefik";
          external = true;
        };
      };

      services = {
        homer.service = rec {
          image = "b4bz/homer:v23.10.1";
          container_name = "homer";
          networks = [ "traefik" ];
          restart = "unless-stopped";
          user = userSetting;
          environment = {
            INIT_ASSETS = "1";
            PORT = "8080";
          };
          volumes = [
            # configuration file is managed by environment.mutable-files
            (storeFor "homer" "/www/assets")
          ];
          labels = (customLib.docker.labels.mkTraefikLabels {
            name = container_name;
            port = 8080;
            domain = config.custom.networking.domain;
          }) // {
            "wud.tag.exclude" = "^latest.*$";
          };
        };

        # Home Automation
        mariadb.service = {
          image = "mariadb:11.3.2";
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
          labels = {
            "wud.display.icon" = "si:mariadb";
            "wud.tag.exclude" = ".*rc.*";
          };
        };

        mosquitto.service = {
          image = "eclipse-mosquitto:2.0.18";
          container_name = "mosquitto";
          restart = "unless-stopped";
          volumes = [
            "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
            "${config.age.secrets.mosquitto_passwords_hashed.path}:/mosquitto/config/passwords.txt:ro"
            (storeFor "mosquitto/data" "/mosquitto/data")
            (storeFor "mosquitto/log" "/mosquitto/log")
          ];
          networks = [ "default" "traefik" ];
          # networks = [ "default" ];
          user = userSetting;
          labels = {
            "traefik.enable" = "true";
            "traefik.tcp.routers.mosquitto.rule" = "HostSNI(`*`)";
            "traefik.tcp.routers.mosquitto.entrypoints" = "mqtt";
            "traefik.tcp.routers.mosquitto.service" = "mosquitto";
            "traefik.tcp.services.mosquitto.loadBalancer.server.port" = "1883";
            "wud.display.icon" = "si:eclipsemosquitto";
          };
        };

        zigbee2mqtt.service = rec {
          image = "koenkk/zigbee2mqtt:1.36.0";
          container_name = "zigbee2mqtt";
          restart = "unless-stopped";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            # configuration file is managed by environment.mutable-files
            (storeFor "zigbee2mqtt" "/app/data")
            "${config.age.secrets.zigbee2mqtt_secrets.path}:/app/data/secrets.yaml:ro"
            "/run/udev:/run/udev:ro"
          ];
          devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
          depends_on = [ "mosquitto" ];
          networks = [ "default" "traefik" ];
          # networks = [ "default" ];
          # user = userSetting;
          labels = customLib.docker.labels.mkTraefikLabels { name = container_name; port = 8080; } // {
            "wud.display.icon" = "si:zigbee";
          };
        };

        nodered.service = rec {
          image = "nodered/node-red:3.1.7";
          container_name = "nodered";
          environment = {
            TZ = "${config.time.timeZone}";
            NODE_RED_ENABLE_PROJECTS = "true";
          };
          restart = "unless-stopped";
          networks = [ "traefik" "default" ];
          # networks = [ "default" ];
          user = userSetting;
          volumes = [
            (storeFor "nodered" "/data")
          ];
          labels = customLib.docker.labels.mkTraefikLabels { name = container_name; port = 1880; } // {
            "wud.tag.exclude" = "^latest.*$";
            "wud.display.icon" = "si:nodered";
          };
        };

        homeassistant.service = rec {
          image = "homeassistant/home-assistant:2024.3.3";
          container_name = "homeassistant";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          restart = "unless-stopped";
          networks = [ "default" "traefik" ];
          # networks = [ "default" ];
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
          labels = customLib.docker.labels.mkTraefikLabels { name = container_name; port = 80; } // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
            "wud.display.icon" = "si:homeassistant";

            "traefik.http.routers.homeassistant.middlewares" = "authentik@docker";
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
