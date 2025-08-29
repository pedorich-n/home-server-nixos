_: {
  services.snapper = {
    snapshotRootOnBoot = false;
    snapshotInterval = "*-*-* *:00:00";

    configs = {
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
}
