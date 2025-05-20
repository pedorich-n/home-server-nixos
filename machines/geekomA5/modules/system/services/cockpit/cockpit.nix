{ config, pkgs, pkgs-unstable, ... }:
{
  custom = {
    networking.ports.tcp.cockpit = { port = 9090; openFirewall = true; };
  };

  environment.systemPackages = [
    pkgs.cockpit-files
    pkgs.cockpit-podman
  ];

  # systemd.sockets.cockpit.listenStreams = lib.mkForce [
  #   "127.0.0.1:${config.custom.networking.ports.tcp.cockpit.portStr}"
  # ];

  systemd.services = {
    cockpit.environment = {
      G_MESSAGES_DEBUG = "all";
    };

    "cockpit-wsinstance-http".environment = {
      G_MESSAGES_DEBUG = "all";
    };
  };

  services = {
    cockpit = {
      enable = true;
      package = pkgs-unstable.cockpit;

      inherit (config.custom.networking.ports.tcp.cockpit) port openFirewall;

      settings = {
        WebService = {
          Origins = "http://cockpit.${config.custom.networking.domain} ws://cockpit.${config.custom.networking.domain}";
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          AllowUnencrypted = true;
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      # middlewares.cockpit = {
      #   headers = {
      #     customRequestHeaders = {
      #       "X-Forwarded-Proto" = "http";
      #     };
      #   };
      # };

      routers.cockpit = {
        entryPoints = [ "web" ];
        rule = "Host(`cockpit.${config.custom.networking.domain}`)";
        service = "cockpit";
        # middlewares = [ "cockpit@file" ];
      };

      services.cockpit = {
        loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.cockpit.portStr}"; }];
      };
    };
  };

}
