{
  config,
  pkgs,
  lib,
  ...
}:
let

  metricsBaseUrl = config.custom.services.caddy.metrics.host;
  localPrometheusEndpoints = lib.mapAttrsToList (name: _route: {
    name = lib.replaceString "-" "_" name;
    url = "${metricsBaseUrl}/${name}";
    autodetection_retry = 60;
  }) config.custom.services.caddy.metrics.routes;
in
{
  sops.templates = {
    "netdata/health_alarm_notify.conf" = {
      owner = config.services.netdata.user;
      group = config.services.netdata.group;
      content = ''
        SEND_TELEGRAM="YES"
        TELEGRAM_BOT_TOKEN="${config.sops.placeholder."netdata/notifications/telegram/bot_token"}"
        DEFAULT_RECIPIENT_TELEGRAM="${config.sops.placeholder."netdata/notifications/telegram/recipient"}"
      '';
    };

    "netdata/prometheus.conf" = {
      owner = config.services.netdata.user;
      group = config.services.netdata.group;
      # https://learn.netdata.cloud/docs/collecting-metrics/generic-collecting-metrics/prometheus-endpoint#options
      file = pkgs.writers.writeYAML "netdata-prometheus.conf" {
        jobs = localPrometheusEndpoints ++ [
          {
            name = "fly_io";
            # Copied from https://github.com/DataDog/integrations-core/blob/cc7e7b52d27ba978e754c/fly_io/datadog_checks/fly_io/check.py#L41-L43
            url = "https://api.fly.io/prometheus/personal/federate?match[]=${lib.escapeURL ''{__name__=~".+"}''}";
            autodetection_retry = 60;
            headers = {
              Authorization = config.sops.placeholder."netdata/prometheus/flyio/token";
            };
          }
        ];
      };
    };
  };
}
