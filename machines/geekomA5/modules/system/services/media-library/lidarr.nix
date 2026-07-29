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

    serviceConfig = {
      # Hardening copied from https://github.com/NixOS/nixpkgs/blob/2f5a153c270b70cb0f8/nixos/modules/services/misc/servarr/sonarr.nix#L90-L122
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      ProtectHome = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      UMask = "002"; # 664 for files, 775 for dirs
      ProtectHostname = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
        "~@debug"
        "~@mount"
        "@chown"
      ];
    };
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
