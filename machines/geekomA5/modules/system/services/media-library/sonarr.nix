{
  config,
  systemdLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.sonarr;
in
{
  custom = {
    networking.ports.tcp.sonarr = {
      port = 31100;
      openFirewall = false;
    };

    services.caddy.hosts.sonarr = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [ "/api*" ];
    };
  };

  systemd.services.sonarr = {
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

  services.sonarr = {
    enable = true;
    group = "media";
    dataDir = "/mnt/store/media-library/sonarr";

    environmentFiles = [
      config.sops.secrets."media-library/sonarr.env".path
    ];

    settings = {
      app = {
        instanceName = "Sonarr";
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
