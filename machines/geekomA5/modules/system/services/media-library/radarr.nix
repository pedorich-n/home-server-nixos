{
  config,
  systemdLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.radarr;
in
{
  custom = {
    networking.ports.tcp.radarr = {
      port = 31200;
      openFirewall = false;
    };

    services.caddy.hosts.radarr = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [ "/api*" ];
    };
  };

  systemd.services.radarr = {
    unitConfig = lib.mkMerge [
      # TODO: Use systemd.services.<name>.name once migrated to native services
      (systemdLib.wantsAfter [
        "qbittorrent.service"
        "sabnzbd.service"
      ])
      (systemdLib.requisiteAfter [
        "zfs.target"
      ])
    ];
  };

  services.radarr = {
    enable = true;
    group = "media";
    dataDir = "/mnt/store/media-library/radarr";

    environmentFiles = [
      config.sops.secrets."media-library/radarr.env".path
    ];

    settings = {
      app = {
        instanceName = "Radarr";
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
