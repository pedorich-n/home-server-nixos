{
  config,
  networkingLib,
  autheliaLib,
  systemdLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
  cfg = config.services.safebucket;
in
{

  custom = {
    networking.ports.tcp.safebucket = {
      port = 32900;
      openFirewall = false;
    };
  };

  systemd.services.safebucket.unitConfig = lib.mkMerge [
    (systemdLib.wantsAfter [
      config.systemd.services.caddy.name
    ])
    (systemdLib.requisiteAfter [
      config.systemd.services.authelia-main.name
    ])
  ];

  services.safebucket = {
    enable = true;

    dataDir = "/var/lib/safebucket";

    environment = {
      APP__LOG_LEVEL = "info";
      APP__API_URL = networkingLib.mkUrl "safebucket";
      APP__WEB_URL = networkingLib.mkUrl "safebucket";
      APP__ALLOWED_ORIGINS = networkingLib.mkUrl "safebucket";
      APP__TRUSTED_PROXIES = "127.0.0.1/32";
      APP__PORT = portsCfg.safebucket.port;
      APP__TRASH_RETENTION_DAYS = 3; # Default is 7
      APP__STATIC_FILES__ENABLED = true;
      APP__AUTHENTICATED_REQUESTS_PER_MINUTE = 5000; # Default is 100
      APP__UNAUTHENTICATED_REQUESTS_PER_MINUTE = 2000; # Default is 20
      APP__REQUEST_TIMEOUT_SECONDS = 30; # Default is 5

      STORAGE__TYPE = "s3";
      STORAGE__S3__USE_TLS = true;
      STORAGE__S3__FORCE_PATH_STYLE = true;

      DATABASE__TYPE = "sqlite";
      DATABASE__SQLITE__PATH = "${cfg.dataDir}/safebucket.db";

      CACHE__TYPE = "redis";
      CACHE__REDIS__HOSTS = "127.0.0.1:${portsCfg.redis-safebucket.portStr}";

      EVENTS__TYPE = "memory";
      EVENTS__QUEUES__NOTIFICATIONS__NAME = "safebucket-notifications";
      EVENTS__QUEUES__BUCKET_EVENTS__NAME = "safebucket-bucket-events";
      EVENTS__QUEUES__OBJECT_DELETION__NAME = "safebucket-object-deletion";

      NOTIFIER__TYPE = "smtp";
      NOTIFIER__SMTP__HOST = "smtp.purelymail.com";
      NOTIFIER__SMTP__PORT = 465;
      NOTIFIER__SMTP__TLS_MODE = "ssl";

      ACTIVITY__TYPE = "filesystem";

      # Uncomment if want to enable local auth
      # AUTH__PROVIDERS__KEYS = "local,authelia";
      # AUTH__PROVIDERS__LOCAL__NAME = "local";
      # AUTH__PROVIDERS__LOCAL__TYPE = "local";
      # AUTH__PROVIDERS__LOCAL__SHARING__ALLOWED = "true";

      AUTH__PROVIDERS__KEYS = "authelia";
      AUTH__PROVIDERS__AUTHELIA__NAME = "Authelia";
      AUTH__PROVIDERS__AUTHELIA__TYPE = "oidc";
      AUTH__PROVIDERS__AUTHELIA__OIDC__ISSUER = autheliaLib.issuerUrl;
      AUTH__PROVIDERS__AUTHELIA__SHARING__ALLOWED = true;

    };

    environmentFiles = [
      config.sops.secrets."safebucket/main.env".path
    ];
  };
}
