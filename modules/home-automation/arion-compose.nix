{ config, pkgs, ... }:
let
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeRoot = "/mnt/ha-store";
  storeFor = localPath: remotePath: "${storeRoot}/${localPath}:${remotePath}";

  staticIPs = {
    dnsmasq = "172.32.0.2";
    homeassistant = "172.32.0.5";
    tailscale = "172.32.0.10";
  };

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) ({
    glances = ./glances/config.nix;
    mosquitto = ./mosquitto/config.nix;
    traefik = ./traefik/configs.nix;
  });

  helpers = builtins.mapAttrs (_: path: pkgs.callPackage path { }) ({
    dnsmasq = ./dnsmasq/helper.nix;
    tailscaleEntryPoint = ./tailscale/entrypoint.nix;
  });
in
{
  environment.systemPackages = with pkgs; [ arion podman-compose ];

  networking.firewall.interfaces."podman+" = {
    allowedUDPPorts = [ 53 5353 ];
    allowedTCPPorts = [ 80 ];
  };

  systemd.services.arion-home-automation = {
    after = [ "network-online.target" ];
    serviceConfig = {
      User = config.users.users.user.name;
      # Group = config.users.groups.podman.name;
      Group = config.users.users.user.group;
    };
  };

  virtualisation.arion = {
    backend = "podman-socket";
    projects = {
      home-automation.settings = {
        enableDefaultNetwork = false;

        docker-compose.volumes = {
          homer = { };
        };

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
          traefik = {
            image = {
              name = "nixpkgs-traefik";
              command = [ "traefik" "--configfile=/config/static.yaml" ];
              contents = [ pkgs.traefik ];
            };
            service = {
              container_name = "traefik";
              ports = [ "80:80" ];
              networks = [ "traefik" ];
              volumes = [
                "/run/podman/podman.sock:/var/run/docker.sock:ro"
                # "/var/run/docker.sock:/var/run/docker.sock:ro"
                "${configs.traefik.static}:/config/static.yaml:ro"
                "${configs.traefik.dynamic}:/config/dynamic.yaml:ro"
              ];
              restart = "unless-stopped";
              labels = {
                "wud.watch" = "false";
              };
              capabilities = {
                CAP_NET_BIND_SERVICE = true;
              };
            };
          };

          homer.service = {
            image = "b4bz/homer:v23.05.1";
            container_name = "homer";
            networks = [ "traefik" ];
            restart = "unless-stopped";
            user = userSetting;
            environment = {
              INIT_ASSETS = "1";
            };
            volumes = [
              "${./homer/config.yml}:/www/assets/config.yml"
              "homer:/www/assets/"
            ];
            labels = {
              "wud.tag.exclude" = "^latest.*$";
            };
          };

          glances = {
            out.service = {
              pid = "host"; # Not implemented in Arion
            };
            service = {
              image = "nicolargo/glances:3.4.0.3-full";
              container_name = "glances";
              networks = [ "traefik" ];
              environment = {
                GLANCES_OPT = "--webserver --disable-left-sidebar --config /etc/glances.conf";
              };
              volumes = [
                "${configs.glances}:/etc/glances.conf:ro"
                "/run/podman/podman.sock:/var/run/podman.sock:ro"
              ];
            };
          };

          portainer.service = {
            image = "portainer/portainer-ce:2.18.4-alpine";
            container_name = "portainer";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
              # "/var/run/docker.sock:/var/run/docker.sock:ro"
              (storeFor "portainer" "/data")
            ];
            networks = [ "traefik" ];
            # user = userSetting;
            restart = "unless-stopped";
            labels = {
              "wud.tag.include" = ''^\d+\.\d+(\.\d+)?-alpine$'';
            };
          };

          whatsupdocker.service = {
            image = "fmartinou/whats-up-docker:6.3.0";
            container_name = "whatsupdocker";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            networks = [ "traefik" ];
            # user = userSetting;
            restart = "unless-stopped";
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
              # "/var/run/docker.sock:/var/run/docker.sock:ro"
              (storeFor "whatsupdocker" "/store")
            ];
            labels = {
              "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
            };
          };

          dnsmasq = {
            image = {
              name = "nixpkgs-dnsmasq";
              command = [
                "dnsmasq"
                "--keep-in-foreground"
                "--log-facility=-"
                "--address=/homeassistant.server.local/${staticIPs.homeassistant}"
              ];
              contents = with pkgs.dockerTools; [ fakeNss helpers.dnsmasq pkgs.dnsmasq ];
            };
            service = {
              container_name = "dnsmasq";
              stop_signal = "SIGKILL";
              restart = "unless-stopped";
              networks.tailscale.ipv4_address = staticIPs.dnsmasq;
              labels = {
                "wud.watch" = "false";
              };
            };
          };

          tailscalse.service = {
            image = "tailscale/tailscale:v1.44.0";
            command = [ "/usr/local/bin/custom-entrypoint.sh" ];
            container_name = "tailscale";
            restart = "unless-stopped";
            environment = {
              TS_ACCEPT_DNS = "true";
              TS_STATE_DIR = "/etc/tailscaled_state/";
              TS_ROUTES = "172.32.0.0/24";
              TS_EXTRA_ARGS = "--hostname=homeassistant-nixos";
            };
            networks.tailscale.ipv4_address = staticIPs.tailscale;
            user = userSetting;
            volumes = [
              (storeFor "tailscale" "/etc/tailscaled_state")
              "${config.age.secrets.tailscale-key.path}:/var/run/key.txt:ro"
              "${helpers.tailscaleEntryPoint}:/usr/local/bin/custom-entrypoint.sh:ro"
            ];
            depends_on = [ "dnsmasq" ];
            labels = {
              "wud.tag.exclude" = "^unstable.*$";
            };
          };

          # Home Automation
          mariadb.service = {
            image = "mariadb:11.0-jammy";
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
              "${config.age.secrets.mariadb-root-password.path}:/var/lib/mysql/root_password:ro"
              "${config.age.secrets.mariadb-user.path}:/var/lib/mysql/user:ro"
              "${config.age.secrets.mariadb-password.path}:/var/lib/mysql/password:ro"
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
            restart = "unless-stopped";
            volumes = [
              "${configs.mosquitto}:/mosquitto/config/mosquitto.conf:ro"
              "${config.age.secrets.mosquitto-passwords.path}:/mosquitto/config/passwords.txt:ro"
              (storeFor "mosquitto/data" "/mosquitto/data")
              (storeFor "mosquitto/log" "/mosquitto/log")
            ];
            networks = [ "default" ];
            user = userSetting;
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
              "${config.age.secrets.zigbee2mqtt-secrets.path}:/app/data/secrets.yaml:ro"
              "${./zigbee2mqtt/configuration.yaml}:/app/data/configuration.yaml:ro"
              "/run/udev:/run/udev:ro"
            ];
            devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
            depends_on = [ "mosquitto" ];
            networks = [ "default" "traefik" ];
            # user = userSetting;
            labels = {
              "wud.display.icon" = "si:zigbee";
            };
          };

          nodered.service = {
            image = "nodered/node-red:3.0";
            container_name = "node-red";
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
            labels = {
              "wud.tag.exclude" = "^latest.*$";
              "wud.display.icon" = "si:nodered";
            };
          };

          homeassistant.service = {
            image = "homeassistant/home-assistant:2023.7";
            container_name = "homeassistant";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            restart = "unless-stopped";
            networks = {
              default = { };
              traefik = { };
              tailscale.ipv4_address = staticIPs.homeassistant;
            };
            # user = userSetting;
            capabilities = {
              CAP_NET_RAW = true;
              CAP_NET_BIND_SERVICE = true;
            };
            volumes = [
              (storeFor "homeassistant" "/config")
              (storeFor "homeassistant/local" "/.local")
              # "${config.age.secrets.ha-secrets.path}:/config/secrets.yaml"
            ];
            labels = {
              "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
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
