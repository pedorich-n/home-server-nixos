{
  config,
  lib,
  networkingLib,
  pkgs,
  systemdLib,
  ...
}:
{
  systemd = {
    services = {

      forgejo-mirror-seeder = {
        description = "Seed Forgejo pull mirrors from the JSON manifest";

        unitConfig = systemdLib.requiresAfter [
          config.systemd.services.forgejo.name
          config.systemd.services.caddy.name
        ];

        startAt = "*-*-* 01:00:00";

        serviceConfig = {
          Type = "oneshot";

          LoadCredential = [
            "manifest:${config.sops.secrets."forgejo-mirror-seeder/repos.json".path}"
            "forgejo-token:${config.sops.secrets."forgejo-mirror-seeder/forgejo_token".path}"
            "github-token:${config.sops.secrets."forgejo-mirror-seeder/github_token".path}"
          ];

          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.forgejo-mirror-seeder)
            "--manifest"
            "%d/manifest"
            "--forgejo-url"
            (networkingLib.mkLocalUrl "git")
            "--forgejo-token-file"
            "%d/forgejo-token"
            "--github-token-file"
            "%d/github-token"
            "--migrate-timeout"
            "3600"
          ];
          TimeoutStartSec = "65min";

          # Hardening
          CapabilityBoundingSet = "";
          DynamicUser = true;
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      restic-backups-forgejo.unitConfig.After = [
        config.systemd.services.forgejo-mirror-seeder.name
      ];
    };

    timers = {
      forgejo-mirror-seeder.timerConfig.Persistent = true;
    };
  };
}
