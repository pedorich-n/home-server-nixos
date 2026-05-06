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
      port = 48000;
      openFirewall = false;
    };

    services.caddy.hosts.dashy = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
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
      extraConfig = "redir ${networkingLib.mkUrl "dashy"}{uri} permanent";
    };

    traefik.dynamicConfigOptions.http = {
      middlewares = {
        dashy-top-level-redirect = {
          redirectRegex = {
            regex = "^https://${config.custom.networking.domain}(.*)";
            replacement = "${networkingLib.mkUrl "dashy"}";
            permanent = true;
          };
        };
      };

      routers = {
        top-level.middlewares = [ "dashy-top-level-redirect@file" ];

        dashy-secure = {
          entryPoints = [ "web-secure" ];
          rule = "Host(`${networkingLib.mkDomain "dashy"}`)";
          service = "dashy-secure";
        };
      };

      services.dashy-secure = {
        loadBalancer.servers = [ { url = "http://127.0.0.1:${portsCfg.portStr}"; } ];
      };
    };
  };

}
