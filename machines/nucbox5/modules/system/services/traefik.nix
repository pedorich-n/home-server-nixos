{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [ 80 1883 ];

  services.traefik = {
    enable = false;
    group = "podman";

    staticConfigOptions = {
      global = {
        sendAnonymousUsage = false;
      };

      api = {
        dashboard = true;
        insecure = true;
      };

      providers = {
        docker = {
          endpoint = "unix:///run/podman/podman.sock";
          network = "traefik";
          exposedByDefault = false;
        };
      };

      entryPoints = {
        web.address = ":80";
        mqtt.address = ":1883";
      };
    };

    dynamicConfigOptions = {
      http = {
        routers = {
          traefik = {
            entryPoints = [ "web" ];
            rule = "Host(`traefik.${config.custom.networking.domain}`)";
            service = "traefik";
          };
        };

        services = {
          traefik = {
            loadBalancer = {
              servers = [{ url = "http://localhost:8080"; }];
            };
          };
        };
      };
    };
  };
}
