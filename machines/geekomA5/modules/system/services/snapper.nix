_:
let
  mkConfigWithDefault =
    subvolume: attrs:
    {
      FSTYPE = "btrfs";
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;

      SUBVOLUME = subvolume;

      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 14;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_QUARTERLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
    }
    // attrs;

in
{
  services.snapper = {
    snapshotRootOnBoot = false;
    snapshotInterval = "*-*-* *:00:00";

    configs = {
      "authentik" = mkConfigWithDefault "/mnt/store/authentik" { };
      "grist" = mkConfigWithDefault "/mnt/store/grist" { };
      "immich" = mkConfigWithDefault "/mnt/store/immich" { };
      "music-history" = mkConfigWithDefault "/mnt/store/music-history" { };
      "paperless" = mkConfigWithDefault "/mnt/store/paperless" { };
    };
  };
}
