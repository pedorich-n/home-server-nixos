{
  config,
  containerLib,
  networkingLib,
  autheliaLib,
  ...
}:
let
  storeRoot = "/mnt/store/safebucket";
  portsCfg = config.custom.networking.ports.tcp;
in
{
  custom = {
    networking.ports.tcp.safebucket = {
      port = 32900;
      openFirewall = false;
    };

    # services.caddy.hosts.safebucket = {
    #   upstream = "http://127.0.0.1:${portsCfg.safebucket.portStr}";
    # };
  };

  virtualisation.quadlet.containers.safebucket = {
    wantsCaddy = true;
    wantsAuthelia = true;
    useGlobalContainers = true;
    usernsAuto.enable = true;

    containerConfig = {
      environments = {
        APP__LOG_LEVEL = "info";
        APP__PROFILE = "default";
        APP__API_URL = networkingLib.mkUrl "safebucket";
        APP__WEB_URL = networkingLib.mkUrl "safebucket";
        APP__ALLOWED_ORIGINS = networkingLib.mkUrl "safebucket";
        APP__TRUSTED_PROXIES = "127.0.0.1/32";
        APP__PORT = "8080";
        APP__TRASH_RETENTION_DAYS = "7";
        APP__STATIC_FILES__ENABLED = "true";

        STORAGE__TYPE = "s3";
        STORAGE__S3__USE_TLS = "true";
        STORAGE__S3__FORCE_PATH_STYLE = "true";

        DATABASE__TYPE = "sqlite";
        DATABASE__SQLITE__PATH = "/app/data/db/safebucket.db";

        CACHE__TYPE = "redis";
        CACHE__REDIS__HOSTS = "host.containers.internal:${portsCfg.redis-safebucket.portStr}";

        EVENTS__TYPE = "memory";
        EVENTS__QUEUES__NOTIFICATIONS__NAME = "safebucket-notifications";
        EVENTS__QUEUES__BUCKET_EVENTS__NAME = "safebucket-bucket-events";
        EVENTS__QUEUES__OBJECT_DELETION__NAME = "safebucket-object-deletion";

        NOTIFIER__TYPE = "smtp";
        NOTIFIER__SMTP__HOST = "smtp.purelymail.com";
        NOTIFIER__SMTP__PORT = "465";
        NOTIFIER__SMTP__TLS_MODE = "ssl";

        ACTIVITY__TYPE = "filesystem";
        ACTIVITY__FILESYSTEM__DIRECTORY = "/app/data/activity";

        # Uncomment if want to enable local auth
        # AUTH__PROVIDERS__KEYS = "local,authelia";
        # AUTH__PROVIDERS__LOCAL__NAME = "local";
        # AUTH__PROVIDERS__LOCAL__TYPE = "local";
        # AUTH__PROVIDERS__LOCAL__SHARING__ALLOWED = "true";

        AUTH__PROVIDERS__KEYS = "authelia";
        AUTH__PROVIDERS__AUTHELIA__NAME = "Authelia";
        AUTH__PROVIDERS__AUTHELIA__TYPE = "oidc";
        AUTH__PROVIDERS__AUTHELIA__OIDC__ISSUER = autheliaLib.issuerUrl;
        AUTH__PROVIDERS__AUTHELIA__SHARING__ALLOWED = "true";

      };
      environmentFiles = [ config.sops.secrets."safebucket/main.env".path ];
      volumes = [
        (containerLib.mkMappedVolumeForUser "${storeRoot}/db" "/app/data/db")
        (containerLib.mkMappedVolumeForUser "${storeRoot}/notifications" "/app/data/notifications")
        (containerLib.mkMappedVolumeForUser "${storeRoot}/activity" "/app/data/activity")
      ];
      publishPorts = [ "127.0.0.1:${portsCfg.safebucket.portStr}:8080" ];
      inherit (containerLib.containerIds) user;
    };
  };

}
