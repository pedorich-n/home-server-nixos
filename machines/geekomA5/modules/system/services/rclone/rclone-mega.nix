{
  config,
  lib,
  pkgs,
  ...
}:
let

  arguments = [
    "--config"
    "/dev/null" # Everything set up via args or envs
    "--read-only"
    "--allow-other"
    "--umask"
    "007" # Allow user and group access
    "--gid"
    (builtins.toString config.users.groups.media.gid)
    "--cache-dir"
    "/var/cache/rclone-mega"
    "--vfs-cache-mode"
    "full"
    "--vfs-cache-max-size"
    "10G"
    "--vfs-cache-max-age"
    "168h" # One week
    "--buffer-size"
    "64M"
    "--timeout"
    "15s"
    "--contimeout"
    "15s"
    "--retries"
    "3"
    "--log-level"
    "INFO"
    "--log-systemd"
  ];

in
{
  users = {
    users.rclone = {
      isSystemUser = true;
      group = "rclone";
    };

    groups.rclone = { };
  };

  systemd.services.rclone-mega = {
    description = "Rclone mount Mega";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "local-fs.target"
    ];

    environment = {
      RCLONE_CONFIG_MEGA_TYPE = "mega";
    };

    path = [
      "/run/wrappers" # To allow access to setuid-capable fusermount binaries
    ];

    serviceConfig = {
      Type = "notify";
      User = config.users.users.rclone.name;
      Group = config.users.groups.rclone.name;
      SupplementaryGroups = [
        config.users.groups.fuse.name
        config.users.groups.media.name
      ];

      ExecStart = "${lib.getExe pkgs.rclone} mount mega: /mnt/rclone/mega ${lib.concatStringsSep " " arguments}";
      Restart = "on-failure";

      EnvironmentFile = config.sops.secrets."rclone/mega.env".path;

      CacheDirectory = "rclone-mega";
      CacheDirectoryMode = "0700";
      SuccessExitStatus = [
        143 # shut down gracefully after receiving a SIGTERM
      ];
    };
  };
}
