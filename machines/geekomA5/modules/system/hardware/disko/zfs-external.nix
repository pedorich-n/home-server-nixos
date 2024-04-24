{
  # See: https://wiki.archlinux.org/title/ZFS

  disko.devices = {
    disk = {
      external_1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST4000VN006-3CW104_WW63HA73"; # Bay 1
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "external";
              };
            };
          };
        };
      };
    };

    zpool = {
      external = {
        type = "zpool";
        mode = "mirror";

        # See: https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
        # See: https://www.high-availability.com/docs/ZFS-Tuning-Guide

        # Properties of the zpool (zpool create -o <options>)
        options = {
          ashift = "12"; # Means 4KiB sector size
        };

        # Properties of the FS on the zpool (zfs set <options>)
        rootFsOptions = {
          compression = "zstd"; # ZSTD is based on LZ4 
          atime = "off"; # Disable Access Time 
          xattr = "sa"; # Store Linux attributes in inodes rather than files in hidden folders

          # "com.sun:auto-snapshot" = "false";
        };

        # Options to pass to `mount`
        mountOptions = [
          "defaults" # Use the default options: rw, suid, dev, exec, auto, nouser, and async.
          "nofail" # Allow machine to boot even if device doesn't exist
        ];

        mountpoint = "/mnt/external";

        datasets = {
          immich = {
            type = "zfs_fs";
            mountpoint = "/immich-library";
          };
        };
      };
    };
  };
}
