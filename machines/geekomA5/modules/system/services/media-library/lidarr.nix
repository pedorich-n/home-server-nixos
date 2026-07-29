{
  config,
  lib,
  pkgs-unstable,
  systemdLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.lidarr;
in
{
  custom = {
    networking.ports.tcp.lidarr = {
      port = 32700;
      openFirewall = false;
    };

    services.caddy.hosts.lidarr = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [ "/api*" ];
    };
  };

  systemd.services.lidarr = {
    unitConfig = lib.mkMerge [
      (systemdLib.wantsAfter [
        "qbittorrent.service"
        config.systemd.services.sabnzbd.name
      ])
      (systemdLib.requisiteAfter [
        "zfs.target"
      ])
    ];
  };

  services.lidarr = {
    enable = true;
    package = pkgs-unstable.lidarr;
    group = "media";
    dataDir = "/mnt/store/media-library/lidarr";

    settings = {
      app = {
        instanceName = "Lidarr";
        launchBrowser = false;
      };
      auth = {
        method = "External";
        required = "DisabledForLocalAddresses";
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
