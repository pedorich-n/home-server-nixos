{
  config,
  lib,
  pkgs,
  networkingLib,
  systemdLib,
  ...
}:
let
  photosRoot = "/mnt/rclone/mega/Photos";
  logRoot = "/var/log/immich-cloud-dumper";

  arguments = [
    "upload"
    "from-folder"
    "--no-ui"
    "--pause-immich-jobs"
    "--log-file"
    "${logRoot}/immich-go_\${TIMESTAMP}.log"
    "--server"
    (networkingLib.mkUrl "immich")
    "--api-key"
    "$API_KEY"
    "--session-tag"
    "--recursive"
    "--into-album"
    (lib.escapeShellArg "To Sort")
    "--manage-burst"
    "Stack"
    "--manage-heic-jpeg"
    "StackCoverJPG"
    "--manage-raw-jpeg"
    "StackCoverJPG"
    photosRoot
  ];
in
{
  systemd = {
    timers.immich-cloud-dumper = {
      description = "Run Immich Cloud Photos Dumper";

      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "*-*-* 01:00:00";
        Persistent = true;
      };
    };

    services.immich-cloud-dumper = {
      description = "Immich Cloud Photos Dumper";

      unitConfig = lib.mkMerge [
        (systemdLib.requiresAfter [
          config.systemd.services.rclone-mega.name
          "immich-server.service"
        ])
        (systemdLib.wantsAfter [
          "network-online.target"
        ])
      ];

      script = ''
        export API_KEY=$(systemd-creds cat api-key)
        export TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

        ${lib.getExe pkgs.immich-go} ${lib.concatStringsSep " " arguments}
      '';

      serviceConfig = {
        LoadCredential = ''api-key:${config.sops.secrets."immich/api/immich-go/key".path}'';
        Restart = "on-failure";

        LogsDirectory = "immich-cloud-dumper";

        # Hardening
        DynamicUser = true;
        SupplementaryGroups = [
          config.users.groups.media.name
        ];
        ReadWritePaths = [
          photosRoot
          logRoot
        ];

        ProtectSystem = "full";
        DeviceAllow = "";
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        ProtectClock = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
      };
    };
  };
}
