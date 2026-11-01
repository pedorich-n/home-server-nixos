{
  config,
  pkgs,
  lib,
  systemdLib,
  ...
}:
let

  tokenPath = "/run/renovate/token";
in
{
  systemd.tmpfiles.settings."10-renovate" = {
    "/run/renovate" = {
      d = {
        mode = "0700";
        user = "root";
        group = "root";
      };
    };
  };

  systemd.services = {
    renovate-prepare-token = {
      description = "Prepare Renovate GitHub App Installation Token";
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
        LoadCredential = "github_app_private_key:${config.sops.secrets."renovate/github_app_private_key".path}";

        # Hardening
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        ReadWritePaths = [ "/run/renovate" ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };

      script = ''
        set -eu

        APP_PRIVATE_KEY="$(cat "''${CREDENTIALS_DIRECTORY}/github_app_private_key")"
        export APP_PRIVATE_KEY

        ${lib.getExe pkgs.github-app-installation-token} > "${tokenPath}.tmp"
        mv "${tokenPath}.tmp" "${tokenPath}"
      '';

      environment = {
        APP_ID = "1721542"; # See https://github.com/settings/apps
        APP_LOGIN = "pedorich-n";
      };

    };

    renovate.unitConfig = systemdLib.requiresAfter [
      config.systemd.services.renovate-prepare-token.name
    ];
  };

  services.renovate.credentials = {
    RENOVATE_TOKEN = tokenPath;
  };
}
