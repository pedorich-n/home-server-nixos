{
  config,
  lib,
  pkgs,
  ...
}:
let
  mailRoot = "/mnt/store/mail/archive";
in
{
  systemd = {
    timers.clean-trash-mail = {
      description = "Timer to clean trash mailboxes";

      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "*-*-* 03:00:00"; # Daily at 3 AM
        Persistent = true;
      };
    };

    services.clean-trash-mail = {
      description = "Clean trash mailboxes older than specified days";

      environment = {
        "DAYS" = "60";
        "MAIL_ROOT" = mailRoot;
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe (pkgs.callPackage ./scripts/_clean-trash.nix { });

        Group = config.custom.services.mbsync.group;

        # Hardening
        ReadWritePaths = [ mailRoot ];
        NoNewPrivileges = true;
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        PrivateMounts = true;
        DynamicUser = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [ ];
      };
    };
  };
}
