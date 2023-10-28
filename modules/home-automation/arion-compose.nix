{ config, pkgs, ... }:
let
  userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";

  storeFor = localPath: remotePath: "/mnt/ha-store/${localPath}:${remotePath}";

  staticIPs = {
    dnsmasq = "172.32.0.2";
    homeassistant = "172.32.0.5";
    tailscale = "172.32.0.10";
  };

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    glances = ./glances/config.nix;
    mosquitto = ./mosquitto/config.nix;
    netdata = ./netdata/config.nix;
  };

  helpers = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    dnsmasq = ./dnsmasq/helper.nix;
    tailscaleEntryPoint = ./tailscale/entrypoint.nix;
  };
in
{
  environment.systemPackages = with pkgs; [ arion podman-compose ];

  networking.firewall.interfaces."podman+" = {
    allowedUDPPorts = [ 53 5353 ];
    # allowedTCPPorts = [ 80 ];
  };

  systemd.services.arion-home-automation = {
    after = [ "network-online.target" ];
    serviceConfig = {
      User = config.users.users.user.name;
      Group = config.users.users.user.group;
    };
  };

  virtualisation.arion = {
    backend = "podman-socket";
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
          homer.service = {
            image = "b4bz/homer:v23.09.1";
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
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.homer.rule" = "Host(`server.local`)";
              "traefik.http.routers.homer.entrypoints" = "web";
              "traefik.http.routers.homer.service" = "homer";
              "traefik.http.services.homer.loadBalancer.server.port" = "8080";
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
              labels = {
                "traefik.enable" = "true";
                "traefik.http.routers.glances.rule" = "Host(`glances.server.local`)";
                "traefik.http.routers.glances.entrypoints" = "web";
                "traefik.http.routers.glances.service" = "glances";
                "traefik.http.services.glances.loadBalancer.server.port" = "61208";
              };
            };
          };

          docker-socker-proxy = {
            service = {
              image = "tecnativa/docker-socket-proxy:0.1.1";
              container_name = "docker_socket_proxy";
              networks = [ "default" ];
              environment = {
                CONTAINERS = 1;
                IMAGES = 1;
              };
              volumes = [
                "/run/podman/podman.sock:/var/run/docker.sock:ro"
              ];
            };
          };

          netdata = {
            out.service = {
              pid = "host"; # Not implemented in Arion
            };
            service = {
              image = "netdata/netdata:v1.43.0";
              container_name = "netdata";
              hostname = "nucbox5";
              networks = [
                "default"
                "traefik"
              ];
              capabilities = {
                SYS_ADMIN = true;
                SYS_PTRACE = true;
              };
              environment = {
                PODMAN_HOST = "http://docker_socket_proxy:2375";
                NETDATA_DISABLE_CLOUD = 1;
              };
              # user = "root:root";
              volumes = [
                (storeFor "netdata/cache" "/var/cache/netdata")
                (storeFor "netdata/config" "/etc/netdata")
                (storeFor "netdata/data" "/var/lib/netdata")
                "${configs.netdata}:/etc/netdata/netdata.conf:ro"
                # "/run/podman/podman.sock:/run/podman/podman.sock:ro"
                "/etc/passwd:/host/etc/passwd:ro"
                "/etc/group:/host/etc/group:ro"
                "/proc:/host/proc:ro"
                "/sys:/host/sys:ro"
                "/etc/os-release:/host/etc/os-release:ro"
              ];
              labels = {
                "traefik.enable" = "true";
                "traefik.http.routers.netdata.rule" = "Host(`netdata.server.local`)";
                "traefik.http.routers.netdata.entrypoints" = "web";
                "traefik.http.routers.netdata.service" = "netdata";
                "traefik.http.services.netdata.loadBalancer.server.port" = "19999";
                "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
              };
              # depends_on = [ "docker_socket_proxy" ];
            };
          };

          portainer.service = {
            image = "portainer/portainer-ce:2.19.1-alpine";
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
              "traefik.enable" = "true";
              "traefik.http.routers.portainer.rule" = "Host(`portainer.server.local`)";
              "traefik.http.routers.portainer.entrypoints" = "web";
              "traefik.http.routers.portainer.service" = "portainer";
              "traefik.http.services.portainer.loadBalancer.server.port" = "9000";
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
              "traefik.enable" = "true";
              "traefik.http.routers.whatsupdocker.rule" = "Host(`whatsupdocker.server.local`)";
              "traefik.http.routers.whatsupdocker.entrypoints" = "web";
              "traefik.http.routers.whatsupdocker.service" = "whatsupdocker";
              "traefik.http.services.whatsupdocker.loadBalancer.server.port" = "3000";
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
            image = "tailscale/tailscale:v1.50.1";
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
            image = "mariadb:11.1.2-jammy";
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
            image = "eclipse-mosquitto:2.0.18";
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
            image = "koenkk/zigbee2mqtt:1.33.1";
            container_name = "zigbee2mqtt";
            restart = "unless-stopped";
            environment = {
              TZ = "${config.time.timeZone}";
            };
            volumes = [
              # configuration file is managed by environment.mutable-files
              (storeFor "zigbee2mqtt" "/app/data")
              "${config.age.secrets.zigbee2mqtt-secrets.path}:/app/data/secrets.yaml:ro"
              "/run/udev:/run/udev:ro"
            ];
            devices = [ "/dev/ttyUSB0:/dev/ttyZigbee" ];
            depends_on = [ "mosquitto" ];
            networks = [ "default" "traefik" ];
            # user = userSetting;
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.zigbee2mqtt.rule" = "Host(`zigbee2mqtt.server.local`)";
              "traefik.http.routers.zigbee2mqtt.entrypoints" = "web";
              "traefik.http.routers.zigbee2mqtt.service" = "zigbee2mqtt";
              "traefik.http.services.zigbee2mqtt.loadBalancer.server.port" = "8080";
              "wud.display.icon" = "si:zigbee";
            };
          };

          nodered.service = {
            image = "nodered/node-red:3.1.0";
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
              "traefik.enable" = "true";
              "traefik.http.routers.nodered.rule" = "Host(`nodered.server.local`)";
              "traefik.http.routers.nodered.entrypoints" = "web";
              "traefik.http.routers.nodered.service" = "nodered";
              "traefik.http.services.nodered.loadBalancer.server.port" = "1880";
              "wud.tag.exclude" = "^latest.*$";
              "wud.display.icon" = "si:nodered";
            };
          };

          homeassistant.service = {
            image = "homeassistant/home-assistant:2023.10.1";
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
              "${config.age.secrets.ha-secrets.path}:/config/secrets.yaml"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.homeassistant.rule" = "Host(`homeassistant.server.local`)";
              "traefik.http.routers.homeassistant.entrypoints" = "web";
              "traefik.http.routers.homeassistant.service" = "homeassistant";
              "traefik.http.services.homeassistant.loadBalancer.server.port" = "80";
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
