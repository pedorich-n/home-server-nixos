{
  config,
  lib,
  pkgs,
  ...
}:
let
  mirrorDir = "/mnt/store/obsidian-mirror";

  mirror = pkgs.writeShellApplication {
    name = "obsidian-mirror";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      rclone copy \
        --config "$CREDENTIALS_DIRECTORY/rclone.conf" \
        --fast-list \
        r2:obsidian-vault/vault ${mirrorDir}/vault
    '';
  };
in
{
  users = {
    groups.obsidian-mirror = { };

    users.obsidian-mirror = {
      isSystemUser = true;
      group = "obsidian-mirror";
    };
  };

  systemd = {
    services.obsidian-mirror = {
      description = "Mirror the Obsidian LiveSync journal from R2";

      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";

        User = "obsidian-mirror";
        Group = "obsidian-mirror";

        ReadWritePaths = [ mirrorDir ];

        LoadCredential = "rclone.conf:${config.sops.templates."obsidian-mirror/rclone.conf".path}";

        ExecStart = lib.getExe mirror;

        # rclone cache
        Environment = [ "XDG_CACHE_HOME=%T/rclone" ];

        # Hardening
        CapabilityBoundingSet = "";
        AmbientCapabilities = [ ];
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;

        RestrictNamespaces = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };

    timers.obsidian-mirror = {
      wantedBy = [ "timers.target" ];

      timerConfig = {
        # :55 so the hourly snapper snapshot of /mnt/store (:00) is at most 5 min stale.
        OnCalendar = "*:55";
        Persistent = true;
      };
    };
  };
}
