{ config, ... }:
{
  custom = {
    networking.ports.tcp = {
      prometheus-podman-exporter.port = 9882;
    };
    services.prometheus-podman-exporter = {
      enable = true;
      port = config.custom.networking.ports.tcp.prometheus-podman-exporter.port;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.metrics-podman = {
      entryPoints = [ "metrics" ];
      rule = "Host(`metrics.${config.custom.networking.domain}`) && Path(`/podman`)";
      service = "metrics-podman";
      middlewares = [ "metrics-replacepath-podman" ];
    };

    services.metrics-podman = {
      loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.prometheus-podman-exporter.portStr}"; }];
    };

    middlewares.metrics-replacepath-podman = {
      replacePath = {
        path = "/metrics";
      };
    };
  };
}
