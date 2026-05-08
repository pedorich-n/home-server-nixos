{
  config,
  networkingLib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.dashy;

  dashy-static = pkgs-unstable.callPackage ./_dashy-static.nix { inherit networkingLib; };
in
{
  custom = {
    networking.ports.tcp.dashy = {
      port = 30000;
      openFirewall = false;
    };

    services.caddy.hosts.dashy = {
      upstream = "http://localhost:${portsCfg.portStr}";
    };
  };

  services = {
    static-web-server = {
      enable = true;

      listen = "127.0.0.1:${portsCfg.portStr}";
      root = dashy-static;
    };

    # Top-level domain redirect: bare domain → dashy.
    caddy.virtualHosts."${config.custom.networking.domain}" = {
      useACMEHost = "local";
      logFormat = null; # Disable access logs
      extraConfig = "redir ${networkingLib.mkUrl "dashy"}{uri} permanent";
    };

  };

}
