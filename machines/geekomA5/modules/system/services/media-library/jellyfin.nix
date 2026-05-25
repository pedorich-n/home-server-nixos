{
  inputs,
  config,
  systemdLib,
  lib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
in
{
  disabledModules = [ "services/misc/jellyfin.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/jellyfin.nix"
  ];

  warnings = lib.optional (lib.versionAtLeast "26.05" config.system.nixos.release) "The updated Jellyfin module now available in stable";

  custom = {
    networking.ports = {
      tcp = {
        jellyfin-native = {
          port = 8096; # Configurable through Web UI
          openFirewall = false;
        };
      };

      udp = {
        jellyfin-client-discovery = {
          port = 1900; # Non-configurable
          openFirewall = true;
        };

      };
    };

    services.caddy.hosts = {
      jellyfin-native = {
        upstream = "http://127.0.0.1:${portsCfg.jellyfin-native.portStr}";
      };
    };
  };

  systemd.services.jellyfin = {
    serviceConfig.SupplemmentaryGroups = [
      config.users.groups.render.name
      config.users.groups.video.name
    ];

    unitConfig = systemdLib.requisiteAfter [
      "zfs.target"
    ];
  };

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;

    group = "media";

    dataDir = "/mnt/store/media-library/jellyfin";

    hardwareAcceleration = {
      enable = true;
      device = "/dev/dri/renderD128";
      type = "vaapi";
    };

    transcoding = {
      enableHardwareEncoding = true;
      enableSubtitleExtraction = true;

      hardwareEncodingCodecs = {
        hevc = true;
      };

      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        vc1 = true;
        vp9 = true;
      };
    };

  };
}
