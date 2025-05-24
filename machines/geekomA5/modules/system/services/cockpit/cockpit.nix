{ config, networkingLib, pkgs, pkgs-unstable, ... }:
{
  custom = {
    networking.ports.tcp.cockpit = { port = 9090; openFirewall = false; };
  };

  #LINK - pkgs/cockpit-plugins/files.nix
  #LINK - pkgs/cockpit-plugins/podman.nix
  environment.systemPackages = [
    pkgs.cockpit-plugins.files
    pkgs.cockpit-plugins.podman
  ];

  services = {
    cockpit = {
      enable = true;
      package = pkgs-unstable.cockpit;

      inherit (config.custom.networking.ports.tcp.cockpit) port openFirewall;

      allowed-origins = [
        (networkingLib.mkUrl "cockpit")
        (networkingLib.mkCustomUrl { scheme = "wss"; service = "cockpit"; })
      ];

      settings = {
        WebService = {
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
