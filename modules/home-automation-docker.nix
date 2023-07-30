{ config, lib, pkgs, ... }:
let
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeRoot = "/mnt/ha-store";
  storeFor = localPath: remotePath: "${storeRoot}/${localPath}:${remotePath}";

  staticIP = {
    dnsmasq = "172.32.0.2";
    homeassistant = "172.32.0.5";
  };

  dnsmasqHelper = pkgs.runCommand "dnsmasq-mkdir" { } ''
    mkdir -p $out/var/run/
  '';

  tailscaleEntrypoint = pkgs.writeScript "tailscale-entrypoint.sh" ''
    #!/bin/sh
    export TS_AUTH_KEY=$(cat /var/run/key.txt)
    /usr/local/bin/containerboot
  '';
in
{

  systemd.services.arion-home-automation.after = [ "network-online.target" ];

  networking = {
    # firewall = {
    #   allowedUDPPorts = [ 53 5353 ];
    #   allowedTCPPorts = [ 80 8123 ];
    # };
  };


  virtualisation.arion = {
    backend = "docker";
    projects = {
      home-automation.settings = {
        enableDefaultNetwork = false;

        networks = {
          default = {
            name = "internal";
            internal = true;
          };
          traefik = {
            name = "traefik";
            ipam = {
              config = [{
                subnet = "172.31.0.0/24";
                gateway = "172.31.0.1";
              }];
            };
          };
          tailscale = {
            name = "tailscale";
            ipam = {
              config = [{
                subnet = "172.32.0.0/24";
                gateway = "172.32.0.1";
              }];
            };
          };
        };

        services = {
          # Server management
          traefik.service = {
            image = "traefik:2.10"; # TODO: build docker image from nixpkgs?
            container_name = "traefik";
            command = [
              "--api.dashboard=true"
              "--api.insecure=true"
              "--providers.file.filename=/config/dynamic-config.yaml" # TODO: manage by nix?
              "--providers.file.watch=true"
              "--entrypoints.web.address=:80"
              "--entrypoints.ha.address=:8123"
            ];
            # user = userSetting;
            ports = [ "80:80" "8123:8123" ];
            networks = [ "traefik" ];
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock:ro"
              "/home/user/ha/dynamic-config.yaml:/config/dynamic-config.yaml"
            ];
            restart = "unless-stopped";
            labels = {
              "wud.display.icon" = "si:traefikproxy";
              "wud.tag.include" = "^\d+\.\d+(\.\d+)?$";
            };
          };

          homer.service = {
            image = "b4bz/homer:v23.05.1";
            container_name = "homer";
            user = userSetting;
            networks = [ "traefik" ];
            restart = "unless-stopped";
            volumes = [
              (storeFor "homer" "/www/assets")
            ];
          };

          # TODO: use Netdata: https://learn.netdata.cloud/docs/installing/docker

          portainer.service = {
            image = "portainer/portainer-ce:2.18.4-alpine";
            container_name = "portainer";
            # user = userSetting;
            environment = {
              TZ = "${config.time.timeZone}";
            };
            volumes = [
              # "/run/podman/podman.sock:/var/run/docker.sock:ro"
              "/var/run/docker.sock:/var/run/docker.sock:ro"
              (storeFor "portainer" "/data")
            ];
            networks = [ "traefik" ];
            restart = "unless-stopped";
            labels = {
              "wud.tag.include" = "^\d+\.\d+(\.\d+)?-alpine$";
            };
          };

          whatsupdocker.service = {
            image = "fmartinou/whats-up-docker:6.3.0";
            container_name = "whatsupdocker";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            # user = userSetting;
            networks = [ "traefik" ];
            restart = "unless-stopped";
            volumes = [
              # "/run/podman/podman.sock:/var/run/docker.sock:ro"
              "/var/run/docker.sock:/var/run/docker.sock:ro"
              (storeFor "whatsupdocker" "/store")
            ];
            labels = {
              "wud.tag.include" = "^\d+\.\d+(\.\d+)?$";
            };
          };

          dnsmasq = {
            image = {
              name = "nixpkgs-dnsmasq";
              command = [
                (toString (lib.getExe pkgs.dnsmasq))
                "--keep-in-foreground"
                "--log-facility=-"
                "--address=/homeassistant.server.local/${staticIP.homeassistant}"
              ];
              contents = with pkgs.dockerTools; [ fakeNss dnsmasqHelper ];
            };
            service = {
              container_name = "dnsmasq";
              # restart = "unless-stopped";
              # user = userSetting;
              networks.tailscale.ipv4_address = staticIP.dnsmasq;
            };
          };

          tailscalse.service = {
            image = "tailscale/tailscale:v1.44.0";
            command = [ "/usr/local/bin/custom-entrypoint.sh" ];
            container_name = "tailscale";
            user = userSetting;
            restart = "unless-stopped";
            environment = {
              TS_ACCEPT_DNS = "true";
              TS_STATE_DIR = "/etc/tailscaled_state/";
              TS_ROUTES = "172.32.0.0/24";
              TS_EXTRA_ARGS = "--hostname=homeassistant-nixos";
            };
            networks.tailscale = { };
            volumes = [
              (storeFor "tailscale" "/etc/tailscaled_state")
              "${config.age.secrets.tailscale-key.path}:/var/run/key.txt"
              "${tailscaleEntrypoint}:/usr/local/bin/custom-entrypoint.sh"
            ];
            depends_on = [ "dnsmasq" ];
          };

          # Home Automation
          mariadb.service = {
            image = "mariadb:11.0-jammy";
            container_name = "mariadb";
            user = userSetting;
            restart = "unless-stopped";
            environment = {
              MARIADB_ROOT_PASSWORD_FILE = "/var/lib/mysql/root_password";
              MARIADB_DATABASE = "ha_database";
              MARIADB_USER_FILE = "/var/lib/mysql/user";
              MARIAD_PASSWORD_FILE = "/var/lib/mysql/password";
              TZ = "${config.time.timeZone}";
            };
            volumes = [
              (storeFor "mariadb" "/var/lib/mysql")
              "${config.age.secrets.mariadb-root-password.path}:/var/lib/mysql/root_password"
              "${config.age.secrets.mariadb-user.path}:/var/lib/mysql/user"
              "${config.age.secrets.mariadb-password.path}:/var/lib/mysql/password"
            ];
            networks = [ "default" ];
            labels = {
              "wud.display.icon" = "si:mariadb";
              "wud.tag.exclude" = ".*rc.*";
            };
          };

          mosquitto.service = {
            image = "eclipse-mosquitto:2.0";
            container_name = "mosquitto";
            user = userSetting;
            restart = "unless-stopped";
            volumes = [
              (storeFor "mosquitto/config" "/mosquitto/config")
              (storeFor "mosquitto/data" "/mosquitto/data")
              (storeFor "mosquitto/log" "/mosquitto/log")
            ];
            networks = [ "default" ];
            labels = {
              "wud.display.icon" = "si:eclipsemosquitto";
            };
          };

          zigbee2mqtt.service = {
            image = "koenkk/zigbee2mqtt:1.31.0";
            container_name = "zigbee2mqtt";
            restart = "unless-stopped";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            volumes = [
              (storeFor "zigbee2mqtt" "/app/data")
              "/run/udev:/run/udev:ro"
            ];
            devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
            depends_on = [ "mosquitto" ];
            networks = [ "default" "traefik" ];
            labels = {
              "wud.display.icon" = "si:zigbee";
            };
          };

          nodered.service = {
            image = "nodered/node-red:3.0";
            container_name = "node-red";
            user = userSetting;
            environment = {
              TZ = "${config.time.timeZone}";
            };
            restart = "unless-stopped";
            networks = [ "traefik" "default" ];
            volumes = [
              (storeFor "nodered" "/data")
            ];
            labels = {
              "wud.tag.exclude" = "^latest.*$";
              "wud.display.icon" = "si:nodered";
            };
          };

          homeassistant.service = {
            image = "homeassistant/home-assistant:2023.6";
            container_name = "homeassistant";
            user = userSetting;
            environment = {
              TZ = "${config.time.timeZone}";
            };
            restart = "unless-stopped";
            networks = {
              default = { };
              traefik = { };
              tailscale.ipv4_address = staticIP.homeassistant;
            };
            capabilities = {
              CAP_NET_RAW = true;
            };
            volumes = [
              (storeFor "homeassistant" "/config")
              (storeFor "homeassistant/local" "/.local")
              # "${config.age.secrets.ha-secrets.path}:/config/secrets.yaml"
            ];
            labels = {
              "wud.tag.include" = "^\d+\.\d+(\.\d+)?$";
              "wud.display.icon" = "si:homeassistant";
            };
            depends_on = [
              "mariadb"
              "mosquitto"
            ];
          };
        };
      };
    };
  };
}
