{
  config,
  systemdLib,
  lib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.prowlarr;
in
{
  custom = {
    networking.ports.tcp.prowlarr = {
      port = 31000;
      openFirewall = false;
    };

    services.caddy.hosts.prowlarr = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [
        "@api"
        "@api_download"
      ];
      # Bypass API calls
      extraConfig = ''
        @api path */api* /api*
        @api_download {
          path */download
          expression {http.request.uri.query}.matches("(?i)(^|&)apikey=")
        }
      '';
    };
  };

  systemd.services.prowlarr = {
    unitConfig = lib.mkMerge [
      # TODO: Use systemd.services.<name>.name once migrated to native services
      (systemdLib.wantsAfter [
        "qbittorrent.service"
        "sabnzbd.service"
      ])
    ];
  };

  services.prowlarr = {
    enable = true;
    package = pkgs-unstable.prowlarr;
    dataDir = "/mnt/store/media-library/prowlarr";

    environmentFiles = [
      config.sops.secrets."media-library/prowlarr.env".path
    ];

    settings = {
      app = {
        instanceName = "Prowlarr";
        launchBrowser = false;
      };
      auth = {
        method = "External";
        required = "Enabled";
      };
      log = {
        level = "Info";
      };
      server = {
        bindAddress = "127.0.0.1";
        port = portsCfg.port;
        enableSsl = false;
      };
    };
  };
}
