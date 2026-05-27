{
  inputs,
  config,
  systemdLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.prowlarr;
in
{
  disabledModules = [ "services/misc/servarr/prowlarr.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/servarr/prowlarr.nix"
  ];

  warnings = lib.optional (lib.versionAtLeast config.system.nixos.release "26.05") "The updated Prowlarr module now available in stable";

  custom = {
    networking.ports.tcp.prowlarr = {
      port = 31000;
      openFirewall = false;
    };

    services.caddy.hosts.prowlarr = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [ "@api" ];
      # Bypass paths that contain /api in them.
      extraConfig = ''
        @api path */api* /api*
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
