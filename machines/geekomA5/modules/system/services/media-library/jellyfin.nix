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

  #LINK - machines/geekomA5/modules/system/services/media-library/jellyfin/secrets.nix:12
  generatedLdapConfig = config.sops.templates."media-library/jellyfin/ldap-auth.xml".path;
in
{
  disabledModules = [ "services/misc/jellyfin.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/jellyfin.nix"
  ];

  warnings = lib.optional (lib.versionAtLeast config.system.nixos.release "26.05") "The updated Jellyfin module now available in stable";

  custom = {
    networking.ports = {
      tcp = {
        jellyfin = {
          port = 8096; # Configurable through Web UI
          openFirewall = false;
        };
      };

      udp = {
        jellyfin-client-discovery = {
          port = 7359; # Non-configurable
          openFirewall = true;
        };

      };
    };

    services.caddy.hosts = {
      jellyfin = {
        upstream = "http://127.0.0.1:${portsCfg.jellyfin.portStr}";
      };
    };
  };

  systemd.services.jellyfin = {
    # Similar to https://github.com/NixOS/nixpkgs/blob/64c08a7ca051951c8eae34e3e3cb1e202fe36786/nixos/modules/services/misc/jellyfin.nix#L387
    preStart = lib.mkAfter ''
      dataDir="${lib.escapeShellArg config.services.jellyfin.dataDir}"
      ldapConfigXml="''${dataDir}/plugins/configurations/LDAP-Auth.xml"

      if [[ -e $ldapConfigXml ]]; then
        # this intentionally removes trailing newlines
        currentText="$(<"$ldapConfigXml")"
        configuredText="$(<${generatedLdapConfig})"
        if [[ $currentText != "$configuredText" ]]; then
          echo "WARN: $ldapConfigXml already exists and is different from the configured settings. Settings NOT applied." >&2
        fi
      else
        cp --update=none-fail -T ${generatedLdapConfig} "$ldapConfigXml"
        chmod u+w "$ldapConfigXml"
      fi
    '';

    serviceConfig.SupplementaryGroups = [
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
