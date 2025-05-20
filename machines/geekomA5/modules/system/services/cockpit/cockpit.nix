{ config, networkingLib, lib, pkgs, pkgs-unstable, ... }:
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
          Origins = lib.concatStringsSep " " [
            (networkingLib.mkUrl "cockpit")
            (networkingLib.mkCustomUrl { scheme = "wss"; service = "cockpit"; })
          ];
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          AllowUnencrypted = true;
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.cockpit = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "cockpit"}`)";
        service = "cockpit";
        # middlewares = [ "cockpit@file" ];
      };

      services.cockpit = {
        loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.cockpit.portStr}"; }];
      };
    };
  };

}
