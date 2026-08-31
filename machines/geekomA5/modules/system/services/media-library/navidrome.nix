{
  config,
  networkingLib,
  systemdLib,
  lib,
  ...
}:
let

  portsCfg = config.custom.networking.ports.tcp.navidrome;
in
{
  custom = {
    networking.ports.tcp.navidrome = {
      port = 32800;
      openFirewall = false;
    };
  };

  custom.services.caddy.hosts.navidrome = {
    upstream = "http://127.0.0.1:${portsCfg.portStr}";
    routes = [
      {
        matcher = "@subsonic";
        auth = "authelia-basic";
      }
      {
        matcher = "@protected";
        auth = "authelia";
      }
    ];
    extraConfig = ''
      @subsonic {
        path /rest/*
        not query c=NavidromeUI
      }
      @protected not path /share/* /rest/*
    '';
  };

  systemd.services.navidrome = {
    unitConfig = systemdLib.requisiteAfter [
      "zfs.target"
    ];

    serviceConfig = {
      RuntimeDirectoryMode = lib.mkForce "0750"; # Default is 0700, but we need caddy to acccess the socket.

      SupplementaryGroups = [
        config.services.caddy.group
      ];
    };
  };

  services.navidrome = {
    enable = true;

    group = "media";

    settings = {
      LogLevel = "info";
      # Address = "unix:${socketPath}";
      Address = "127.0.0.1";
      Port = portsCfg.port;
      UnixSocketPerm = "0666";
      BaseUrl = networkingLib.mkLocalUrl "navidrome";

      DataFolder = "/mnt/store/media-library/navidrome";

      MusicFolder = "/mnt/external/data-library/media/music";
      TranscodingCacheSize = "250MiB";

      EnableUserEditing = false;
      ExtAuth = {
        # TrustedSources = "@"; # Used when runnins using unix socket
        TrustedSources = "127.0.0.1/32";
        UserHeader = "Remote-User";
      };

      ListenBrainz = {
        BaseURL = "${networkingLib.mkLocalUrl "multiscrobbler"}/1/";
      };
    };
  };
}
