{ config, ... }:
{
  custom.networking.ports.tcp = {
    traefik-dashboard = { port = 8080; openFirewall = false; };
    traefik-web = { port = 80; openFirewall = true; };
    traefik-mqtt = { port = 1883; openFirewall = true; };
    traefik-metrics = { port = 9100; openFirewall = false; };
  };

  services.traefik = {
    enable = true;
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
        web.address = ":${builtins.toString config.custom.networking.ports.tcp.traefik-web.port}";
        mqtt.address = ":${builtins.toString config.custom.networking.ports.tcp.traefik-mqtt.port}";
        metrics.address = ":${builtins.toString config.custom.networking.ports.tcp.traefik-metrics.port}";
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
              servers = [{ url = "http://localhost:${builtins.toString config.custom.networking.ports.tcp.traefik-dashboard.port}"; }];
            };
          };
        };
      };
    };
  };
}
