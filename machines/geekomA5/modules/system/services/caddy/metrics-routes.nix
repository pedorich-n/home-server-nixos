{
  config,
  lib,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
  routes = config.custom.caddy.metrics.routes;

  host = networkingLib.mkCustomUrl {
    scheme = "http";
    service = "metrics";
    port = portsCfg.caddy-metrics.port;
  };
in
{
  options.custom.caddy.metrics.routes = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Backend base URL, e.g. http://localhost:8081";
          };
          metricsPath = lib.mkOption {
            type = lib.types.str;
            default = "/metrics";
            description = "Path on the backend to proxy to";
          };
        };
      }
    );
    default = { };
    description = "Reverse proxy routes served on the Caddy metrics virtual host (${host})";
  };

  config = lib.mkIf (routes != { }) {
    services.caddy.virtualHosts."${host}" = {
      extraConfig = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: route: ''
          handle /${name} {
            rewrite * ${route.metricsPath}
            reverse_proxy ${route.url}
          }
        '') routes
      );
    };
  };
}
