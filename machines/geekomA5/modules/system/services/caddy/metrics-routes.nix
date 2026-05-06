{
  config,
  lib,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
  cfg = config.custom.services.caddy.metrics;

  host = networkingLib.mkCustomUrl {
    scheme = "http";
    service = "metrics";
    port = portsCfg.caddy-metrics.port;
  };
in
{
  options.custom.services.caddy.metrics = {
    host = lib.mkOption {
      type = lib.types.str;
      default = host;
      description = "Host (including port) to serve Caddy metrics on, e.g. http://metrics:9200";
    };

    routes = lib.mkOption {
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
  };

  config = lib.mkIf (cfg.routes != { }) {
    services.caddy.virtualHosts."${cfg.host}" = {
      extraConfig = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: route: ''
          handle /${name} {
            rewrite * ${route.metricsPath}
            reverse_proxy ${route.url}
          }
        '') cfg.routes
      );
    };
  };
}
