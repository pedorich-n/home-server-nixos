{
  config,
  lib,
  networkingLib,
  pkgs,
  systemdLib,
  ...
}:
{
  systemd.services.holiday-sync = {
    description = "Sync public holidays into Radicale";

    wantedBy = [ "multi-user.target" ];

    environment = {
      RADICALE_URL = networkingLib.mkLocalUrl "radicale";
      RADICALE_USER_FILE = "%d/radicale_user";
      RADICALE_PASSWORD_FILE = "%d/radicale_password";
    };

    unitConfig = systemdLib.wantsAfter [
      config.systemd.services.caddy.name
      config.systemd.services.radicale.name
    ];

    # Re-run whenever the packaged script or its libraries change, instead of checking on a timer.
    restartTriggers = [ pkgs.holiday-sync ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "10min";

      StateDirectory = "holiday-sync";

      LoadCredential = [
        "radicale_user:${config.sops.secrets."lldap/users/service_radicale_holidays/username".path}"
        "radicale_password:${config.sops.secrets."lldap/users/service_radicale_holidays/password".path}"
      ];

      ExecStart = lib.getExe pkgs.holiday-sync;

      # Hardening
      CapabilityBoundingSet = "";
      DynamicUser = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
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
}
