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


        # See https://github.com/nix-community/disko/issues/469#issuecomment-1944931386 for difference between `mountpoint` and `options.mountpoint`/`rootFsOptions.mountpoint`

        # Properties of the FS on the zpool (zfs set <options>)
        rootFsOptions = {
          compression = "zstd"; # ZSTD is based on LZ4 
          atime = "off"; # Disable Access Time 
          xattr = "sa"; # Store Linux attributes in inodes rather than files in hidden folders
          mountpoint = "/mnt/external"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
        };

        mountpoint = "/mnt/external"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko

        datasets = {
          immich = {
            type = "zfs_fs";
            options.mountpoint = "/mnt/external/immich-library"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
            mountpoint = "/mnt/external/immich-library"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko
          };
        };
      };
    };
  };

  # See https://github.com/nix-community/disko/issues/581
  fileSystems = {
    "/mnt/external".options = [ "noauto" ];
    "/mnt/external/immich-library".options = [ "noauto" ];
  };
}
