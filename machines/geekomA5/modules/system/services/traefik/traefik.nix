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
      log = {
        level = "INFO";
      };

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
        web.address = ":${config.custom.networking.ports.tcp.traefik-web.portStr}";
        mqtt.address = ":${config.custom.networking.ports.tcp.traefik-mqtt.portStr}";
        metrics.address = ":${config.custom.networking.ports.tcp.traefik-metrics.portStr}";
      };
    };

    dynamicConfigOptions = {
      http = {
        middlewares = {
          authentik-homepage = {
            redirectRegex = {
              regex = "^http://${config.custom.networking.domain}(.*)";
              replacement = ''http://authentik.${config.custom.networking.domain}''${1}'';
              permanent = true;
            };
          };
        };

        routers = {
          top-level = {
            entrypoints = [ "web" ];
            rule = "Host(`${config.custom.networking.domain}`)";
            service = "noop@internal";
            middlewares = [ "authentik-homepage@file" ];
          };

          traefik = {
            entryPoints = [ "web" ];
            rule = "Host(`traefik.${config.custom.networking.domain}`)";
            service = "traefik";
            middlewares = [ "authentik@docker" ];
          };
        };

        services = {
          traefik = {
            loadBalancer = {
              servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.traefik-dashboard.portStr}"; }];
            };
          };
        };
      };
    };
  };
}
