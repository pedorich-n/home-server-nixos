{
  config,
  lib,
  pkgs,
  networkingLib,
  systemdLib,
  ...
}:
let
  arguments = [
    "upload"
    "from-folder"
    "--no-ui"
    "--pause-immich-jobs"
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
    "/mnt/rclone/mega/Photos"
  ];
in
{
  systemd = {
    # timers.immich-cloud-dumper = {
    #   description = "Run Immich Cloud Photos Dumper";

    #   timerConfig = {
    #     OnCalendar = "*-*-* 21:00:00";
    #   };
    # };

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

        ${lib.getExe pkgs.immich-go} ${lib.concatStringsSep " " arguments}
      '';

      serviceConfig = {
        LoadCredential = ''api-key:${config.sops.secrets."immich/api/immich-go/key".path}'';
        Restart = "on-failure";

        User = config.users.users.user.name;
        Group = config.users.users.user.group;
      };
    };
  };
}
