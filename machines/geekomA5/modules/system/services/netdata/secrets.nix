{
  config,
  pkgs,
  lib,
  networkingLib,
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
      # See https://learn.netdata.cloud/docs/collecting-metrics/generic-collecting-metrics/prometheus-endpoint#options
      file = pkgs.writers.writeYAML "netdata-prometheus.conf" {
        jobs = lib.lists.flatten [
          localPrometheusEndpoints
          [
            {
              name = "fly_io";
              # Copied from https://github.com/DataDog/integrations-core/blob/cc7e7b52d27ba978e754c/fly_io/datadog_checks/fly_io/check.py#L41-L43
              url = "https://api.fly.io/prometheus/personal/federate?match[]=${lib.escapeURL ''{__name__=~".+"}''}";
              autodetection_retry = 60;
              headers = {
                Authorization = config.sops.placeholder."netdata/prometheus/flyio/token";
              };
            }
          ]
          (lib.optional config.services.tailscale.enable {
            # See https://tailscale.com/docs/reference/tailscale-client-metrics
            name = "tailscale";
            url = "http://100.100.100.100/metrics";
          })
        ];
      };
    };

    "netdata/httpcheck.conf" = {
      owner = config.services.netdata.user;
      group = config.services.netdata.group;
      # See https://learn.netdata.cloud/docs/collecting-metrics/collectors/synthetic-testing/http-endpoints#options
      file = pkgs.writers.writeYAML "netdata-httpcheck.conf" {
        update_every = 30;
        autodetection_retry = 15;
        jobs = [
          {
            name = "Airtrail";
            url = "${networkingLib.mkUrl "airtrail"}/api/ping";
          }
          {
            name = "Audiobookshelf";
            url = "${networkingLib.mkUrl "audiobookshelf"}/healthcheck";
          }
          {
            name = "Authelia";
            url = "${networkingLib.mkUrl "authelia"}/api/health";
          }
          {
            name = "Librechat";
            url = "${networkingLib.mkUrl "chat"}/health";
          }
          {
            name = "Forgejo";
            url = "${networkingLib.mkUrl "git"}/api/v1/version";
          }
          {
            name = "GiteaMirror";
            url = "${networkingLib.mkUrl "gitea-mirror"}/api/health";
          }
          {
            name = "Grist";
            url = "${networkingLib.mkUrl "grist"}/status";
          }
          {
            name = "HomeAssistant";
            url = "${networkingLib.mkUrl "homeassistant"}/api/"; # Trailing slash is important!
            headers = {
              Authorization = "Bearer ${config.sops.placeholder."homeassistant/api/key"}";
            };
          }
          {
            name = "Immich";
            url = "${networkingLib.mkUrl "immich"}/api/server/ping";
          }
          {
            name = "Jellyfin";
            url = "${networkingLib.mkUrl "jellyfin"}/health";
          }
          {
            name = "Koito";
            url = "${networkingLib.mkUrl "koito"}/apis/web/v1/health";
          }
          {
            name = "LLDAP";
            url = "${networkingLib.mkUrl "lldap"}/health";
          }
          {
            name = "Mousehole";
            url = "${networkingLib.mkUrl "mousehole"}/health";
          }
          {
            name = "MultiScrobbler";
            url = "${networkingLib.mkUrl "multiscrobbler"}/api/health";
          }
          {
            name = "N8N";
            url = "${networkingLib.mkUrl "n8n"}/healthz";
          }
          {
            name = "OliveTin";
            url = "${networkingLib.mkUrl "olivetin"}/readyz";
          }
          {
            name = "Paperless";
            url = "${networkingLib.mkUrl "paperless"}/api/statistics/"; # Trailing slash is important!
            headers = {
              Authorization = "Token ${config.sops.placeholder."paperless/api/key"}";
            };
          }
          {
            name = "Prowlarr";
            url = "${networkingLib.mkUrl "prowlarr"}/api/v1/health";
            headers = {
              "X-Api-Key" = config.sops.placeholder."prowlarr/api/key";
            };
          }
          {
            name = "qBittorrent";
            url = "${networkingLib.mkUrl "qbittorrent"}/api/v2/app/buildInfo";
          }
          {
            name = "Radarr";
            url = "${networkingLib.mkUrl "radarr"}/api/v3/health";
            headers = {
              "X-Api-Key" = config.sops.placeholder."radarr/api/key";
            };
          }
          {
            name = "SABnzbd";
            url = "${networkingLib.mkUrl "sabnzbd"}/api?mode=version";
          }
          {
            name = "Shelfmark";
            url = "${networkingLib.mkUrl "shelfmark"}/api/health";
          }
          {
            name = "Sonarr";
            url = "${networkingLib.mkUrl "sonarr"}/api/v3/health";
            headers = {
              "X-Api-Key" = config.sops.placeholder."sonarr/api/key";
            };
          }
          {
            name = "Trek";
            url = "${networkingLib.mkUrl "trek"}/api/health";
          }
          # Zigbee2MQTT doesn't have any meaningful healthcheck endpoints
        ];
      };
    };
  };
}
