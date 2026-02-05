_: {
  services.zfs = {
    autoSnapshot = {
      enable = true;
      # See all arguments: https://github.com/bdrewery/zfstools/blob/4f6185b15d5f9cc575fe8f1175db6ca04d5a1328/bin/zfs-auto-snapshot#L9-L18
      flags = "--keep-zero-sized-snapshots --parallel-snapshots --utc";

      frequent = 12; # 3 hours, every 15 minutes
      hourly = 48;
      daily = 30;
      weekly = 0;
      monthly = 0;
    };

    autoScrub = {
      enable = true;
      interval = "Thu *-*-* 04:00:00"; # Every Thursday at 04:00
    };
  };
}
