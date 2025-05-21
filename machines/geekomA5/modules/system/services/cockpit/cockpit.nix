{ config, networkingLib, lib, pkgs, pkgs-unstable, ... }:
{
  custom = {
    networking.ports.tcp.cockpit = { port = 9090; openFirewall = false; };
  };

  environment.systemPackages = [
    pkgs.cockpit-files
    pkgs.cockpit-podman
  ];

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
        service = "cockpit-secure";
      };

      services.cockpit-secure = {
        loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.cockpit.portStr}"; }];
      };
    };
  };

}
