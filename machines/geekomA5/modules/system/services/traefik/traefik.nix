{ config, ... }:
{
  custom.networking.ports = {
    tcp = {
      traefik-dashboard = { port = 8080; openFirewall = false; };
      traefik-ldap = { port = 389; openFirewall = true; };
      traefik-mqtt = { port = 1883; openFirewall = true; };
      traefik-web = { port = 80; openFirewall = true; };
      traefik-web-secure = { port = 443; openFirewall = true; };
      traefik-metrics = { port = 9100; openFirewall = false; };
    };
    udp = {
      traefik-jellyfin-service-discovery = { port = 1900; openFirewall = true; };
      traefik-jellyfin-client-discovery = { port = 7359; openFirewall = true; };
    };
  };

  users.users.traefik.extraGroups = [ "podman" ];

  services.traefik = {
    enable = true;

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


      certificatesResolvers.step-ca = {
        acme = {
          email = "";
          caServer = "https://ca.${config.custom.networking.domain}:${config.custom.networking.ports.tcp.step-ca.portStr}/acme/acme/directory";
          storage = "/var/lib/traefik/acme.json";
          tlsChallenge = { };
        };
      };

      entryPoints = {
        ldap.address = ":${config.custom.networking.ports.tcp.traefik-ldap.portStr}";
        mqtt.address = ":${config.custom.networking.ports.tcp.traefik-mqtt.portStr}";

        metrics.address = ":${config.custom.networking.ports.tcp.traefik-metrics.portStr}";
        web.address = ":${config.custom.networking.ports.tcp.traefik-web.portStr}";
        web-secure = {
          address = ":${config.custom.networking.ports.tcp.traefik-web-secure.portStr}";
          http = {
            tls.certresolver = "step-ca";
          };
        };

        jellyfin-service-discovery.address = ":${config.custom.networking.ports.udp.traefik-jellyfin-service-discovery.portStr}/udp";
        jellyfin-client-discovery.address = ":${config.custom.networking.ports.udp.traefik-jellyfin-client-discovery.portStr}/udp";
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
            entryPoints = [ "web" "web-secure" ];
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
