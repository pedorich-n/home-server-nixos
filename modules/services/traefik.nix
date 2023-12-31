{
  networking.firewall.allowedTCPPorts = [ 80 1883 ];

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
        web.address = ":80";
        mqtt.address = ":1883";
      };
    };

    dynamicConfigOptions = {
      http = {
        routers = {
          traefik = {
            entryPoints = [ "web" ];
            rule = "Host(`traefik.server.local`)";
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
