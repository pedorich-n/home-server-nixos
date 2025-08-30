_: {
  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "Wed *-*-* 04:00:00"; # Every Wednesday at 04:00

      fileSystems = [
        "/mnt/store"
      ];
    };

    snapper = {
      snapshotRootOnBoot = false;
      snapshotInterval = "*-*-* *:00:00";

      configs = {
        # See all arguments: https://man.archlinux.org/man/snapper-configs.5.en
        "store" = {
          FSTYPE = "btrfs";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          SUBVOLUME = "/mnt/store";

          TIMELINE_LIMIT_HOURLY = 24;
          TIMELINE_LIMIT_DAILY = 14;
          TIMELINE_LIMIT_WEEKLY = 4;
          TIMELINE_LIMIT_MONTHLY = 0;
          TIMELINE_LIMIT_QUARTERLY = 0;
          TIMELINE_LIMIT_YEARLY = 0;
        };
      };
    };
  };
}
