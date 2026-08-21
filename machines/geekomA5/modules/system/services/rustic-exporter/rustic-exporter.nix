{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.rustic-exporter;
in
{
  custom = {
    networking.ports.tcp.rustic-exporter = {
      port = 33100;
      openFirewall = false;
    };

    services = {
      caddy.metrics.routes = {
        rustic-exporter = {
          url = "http://127.0.0.1:${portsCfg.portStr}";
        };
      };

      rustic-exporter = {
        enable = true;
        inherit (portsCfg) port;

        configFile = config.sops.templates."rustic-exporter/config.toml".path;
      };
    };
  };
}
