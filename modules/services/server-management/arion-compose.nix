{ config, pkgs, ... }:
let
  storeFor = localPath: remotePath: "/mnt/ha-store/${localPath}:${remotePath}";

  configs = builtins.mapAttrs (_: path: pkgs.callPackage path { }) {
    netdata = ./netdata/config.nix;
  };
in
{
  environment.systemPackages = with pkgs; [ arion podman-compose ];

  systemd.services.arion-server-management = {
    after = [ "network-online.target" ];
  };

  virtualisation.arion.projects = {
    server-management.settings = {
      enableDefaultNetwork = false;

      networks = {
        default = {
          name = "internal-server-management";
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
      };

      services = {
        docker-socket-proxy = {
          service = {
            # nightly release as of 2023-10-23
            image = "tecnativa/docker-socket-proxy@sha256:3ac4c484db4d55297417eb505cca95ee902b24d92fafe717c89b01c6d4377673";
            container_name = "docker-socket-proxy";
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
            image = "netdata/netdata:v1.43.2";
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
              PODMAN_HOST = "http://docker-socket-proxy:2375";
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
            depends_on = [ "docker-socket-proxy" ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.netdata.rule" = "Host(`netdata.server.local`)";
              "traefik.http.routers.netdata.entrypoints" = "web";
              "traefik.http.routers.netdata.service" = "netdata";
              "traefik.http.services.netdata.loadBalancer.server.port" = "19999";
              "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
            };
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
      };
    };
  };
}
