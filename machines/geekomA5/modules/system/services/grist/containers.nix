{
  config,
  containerLib,
  autheliaLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/grist";
  portsCfg = config.custom.networking.ports.tcp.grist;
in
{
  custom = {
    networking.ports.tcp.grist = {
      port = 31500;
      openFirewall = false;
    };

    services.caddy.hosts.grist = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  virtualisation.quadlet.containers.grist = {
    wantsCaddy = true;
    wantsAuthelia = true;
    useGlobalContainers = true;
    usernsAuto = {
      enable = true;
      size = 65535;
    };

    containerConfig = {
      environments = rec {
        GRIST_DOMAIN = networkingLib.mkDomain "grist";
        APP_HOME_URL = networkingLib.mkUrl "grist";

        GRIST_HIDE_UI_ELEMENTS = "billing";
        GRIST_SUPPORT_ANON = "false";

        GRIST_OIDC_SP_HOST = "${APP_HOME_URL}";
        GRIST_OIDC_IDP_ISSUER = autheliaLib.issuerUrl;
        GRIST_OIDC_IDP_SKIP_END_SESSION_ENDPOINT = "true";

        GRIST_DOCS_MINIO_ENDPOINT = networkingLib.mkDomain "storage";
        GRIST_DOCS_MINIO_USE_SSL = "1";
        GRIST_DOCS_MINIO_BUCKET_REGION = config.services.minio.region;

        GRIST_SNAPSHOT_TIME_CAP = builtins.toJSON {
          hour = 24;
          day = 7;
          isoWeek = 4;
          month = 3;
          year = 0;
        };
        GRIST_SNAPSHOT_KEEP = "5";

        # This function performs HTTP requests in a similar way to requests.request
        GRIST_ENABLE_REQUEST_FUNCTION = "1";
      };
      environmentFiles = [ config.sops.secrets."grist/main.env".path ];
      volumes = [
        (containerLib.mkMappedVolumeForUser "${storeRoot}/persist" "/persist")
      ];
      publishPorts = [ "127.0.0.1:${portsCfg.portStr}:8484" ];
      inherit (containerLib.containerIds) user;
    };
  };

}
