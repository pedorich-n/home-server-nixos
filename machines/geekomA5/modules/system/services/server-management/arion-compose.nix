{ config, pkgs, lib, dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/server-management/${localPath}:${remotePath}";

  configs = builtins.mapAttrs (_: path: import path { inherit config pkgs lib; }) {
    netdata = ./netdata/_config.nix;
  };
in
{

  virtualisation.arion.projects = {
    server-management.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "server-management") // dockerLib.externalTraefikNetwork;

      services = {
        docker-socket-proxy = {
          service = {
            image = "tecnativa/docker-socket-proxy:0.1.2";
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
          service = rec {
            image = "netdata/netdata:v1.45.1";
            container_name = "netdata";
            hostname = config.networking.hostName;
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
              # NETDATA_DISABLE_CLOUD = 0;
            };
            # user = "root:root";
            volumes = [
              (storeFor "netdata/cache" "/var/cache/netdata")
              (storeFor "netdata/config" "/etc/netdata")
              (storeFor "netdata/data" "/var/lib/netdata")
              "${configs.netdata.main}:/etc/netdata/netdata.conf:ro"
              "${configs.netdata.prometheus}:/etc/netdata/go.d/prometheus.conf:ro"
              "/etc/passwd:/host/etc/passwd:ro"
              "/etc/group:/host/etc/group:ro"
              "/proc:/host/proc:ro"
              "/etc/localtime:/etc/localtime:ro"
              "/sys:/host/sys:ro"
              "/var/log:/host/var/log:ro"
              "/etc/os-release:/host/etc/os-release:ro"
            ];
            depends_on = [ "docker-socket-proxy" ];
            labels = dockerLib.mkTraefikLabels { name = container_name; port = 19999; } // {
              "wud.tag.include" = ''^v\d+\.\d+(\.\d+)?'';
            };
          };
        };

        portainer.service = rec {
          image = "portainer/portainer-ce:2.20.0-alpine";
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
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; } // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?-alpine$'';
          };
        };

        whatsupdocker.service = rec {
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
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 3000; } // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
          };
        };
      };
    };
  };
}
