{
  config,
  networkingLib,
  ...
}:
{
  custom.networking.ports.tcp = {
    # traefik-dashboard = {
    #   port = 8080;
    #   openFirewall = false;
    # };
    # traefik-web = {
    #   port = 80;
    #   openFirewall = true;
    # };
    # traefik-web-secure = {
    #   port = 443;
    #   openFirewall = true;
    # };
  };

  # users.users.traefik.extraGroups = [ "podman" ];

  systemd.services.traefik = {
    serviceConfig.SupplementaryGroups = [
      config.security.acme.certs.local.group
    ];
  };

  services.traefik = {
    enable = false;

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
        web = {
          address = ":${config.custom.networking.ports.tcp.traefik-web.portStr}";
          http.redirections = {
            entryPoint = {
              to = "web-secure";
              scheme = "https";
            };
          };
        };
        web-secure = {
          address = ":${config.custom.networking.ports.tcp.traefik-web-secure.portStr}";
          http.tls = {
            # This tells Traefik to use TLS for this entry point, even without body
          };

          transport = {
            respondingTimeouts = {
              readTimeout = "20m"; # Default is 60s
              idleTimeout = "10m"; # Default is 180s
              writeTimeout = "0s"; # Default value
            };
          };
        };

        # jellyfin-service-discovery.address = ":${config.custom.networking.ports.udp.traefik-jellyfin-service-discovery.portStr}/udp";
        # jellyfin-client-discovery.address = ":${config.custom.networking.ports.udp.traefik-jellyfin-client-discovery.portStr}/udp";
      };
    };

    dynamicConfigOptions = {
      tls = {
        certificates = [
          {
            certFile = "${config.security.acme.certs.local.directory}/fullchain.pem";
            keyFile = "${config.security.acme.certs.local.directory}/key.pem";
          }
        ];

        stores.default.defaultCertificate = {
          certFile = "${config.security.acme.certs.local.directory}/fullchain.pem";
          keyFile = "${config.security.acme.certs.local.directory}/key.pem";
        };
      };

      http = {
        routers = {
          top-level = {
            entrypoints = [ "web-secure" ];
            rule = "Host(`${config.custom.networking.domain}`)";
            service = "noop@internal";
          };

          traefik-secure = {
            entryPoints = [ "web-secure" ];
            rule = "Host(`${networkingLib.mkDomain "traefik"}`)";
            service = "traefik";
            middlewares = [ "authelia@file" ];
          };
        };

        services = {
          traefik = {
            loadBalancer = {
              servers = [
                { url = "http://localhost:${config.custom.networking.ports.tcp.traefik-dashboard.portStr}"; }
              ];
            };
          };
        };
      };
    };
  };
}
