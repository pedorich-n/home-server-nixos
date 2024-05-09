{
  services.zfs.autoSnapshot = {
    enable = true;
    # See all arguments: https://github.com/bdrewery/zfstools/blob/4f6185b15d5f9cc575fe8f1175db6ca04d5a1328/bin/zfs-auto-snapshot#L9-L18
    flags = "--keep-zero-sized-snapshots --parallel-snapshots --utc";

    frequent = 4;
    hourly = 24;
    daily = 14;
    weekly = 4;
    monthly = 6;
  };
}
