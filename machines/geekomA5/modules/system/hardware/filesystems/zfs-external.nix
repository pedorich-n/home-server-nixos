{
  # NOTE: https://wiki.archlinux.org/title/ZFS

  disko.devices = {
    disk = {
      external_1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST4000VN006-3CW104_WW63HA73"; # Bay 1
        content = {
          type = "zfs";
          pool = "external";
        };
      };

      external_2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST4000VN006-3CW104_WW63M8ER"; # Bay 2
        content = {
          type = "zfs";
          pool = "external";
        };
      };
    };

    zpool = {
      external = {
        type = "zpool";
        mode = "mirror";

        # NOTE: https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
        # NOTE: https://www.high-availability.com/docs/ZFS-Tuning-Guide
        # NOTE: https://jrs-s.net/2019/04/03/on-zfs-recordsize/

        # Properties of the zpool (zpool create -o <options>)
        options = {
          ashift = "12"; # Means 4KiB sector size
        };


        # Properties of the FS on the zpool (zfs set <options>)
        rootFsOptions = {
          compression = "zstd"; # ZSTD is based on LZ4 
          atime = "off"; # Disable Access Time 
          xattr = "sa"; # Store Linux attributes in inodes rather than files in hidden folders
          mountpoint = "/mnt/external"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
          "com.sun:auto-snapshot" = "false"; # Don't take snapshots of root
        };

        mountpoint = "/mnt/external"; # fstab mountpoint

        datasets = {
          immich = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/immich-library"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
              recordsize = "1M"; # Better read performance for "large" files like images, videos, etc.
              "com.sun:auto-snapshot" = "true";
            };
            mountpoint = "/mnt/external/immich-library"; # fstab mountpoint
          };

          paperless = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/paperless-library";
              quota = "10G";
              "com.sun:auto-snapshot" = "true";
            };
            mountpoint = "/mnt/external/paperless-library";
          };

          data = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/data-library";
              quota = "1T";
              recordsize = "1M"; # Better read performance for "large" files like images, videos, etc.
              "com.sun:auto-snapshot" = "false"; # Not worth saving (yet?)
            };
            mountpoint = "/mnt/external/data-library"; # fstab mountpoint
          };
        };
      };
    };
  };

  # NOTE https://github.com/nix-community/disko/issues/581
  fileSystems = {
    "/mnt/external".options = [ "nofail" "x-systemd.requires=zfs.target" ];
    "/mnt/external/immich-library".options = [ "nofail" "x-systemd.requires=zfs.target" ];
    "/mnt/external/paperless-library".options = [ "nofail" "x-systemd.requires=zfs.target" ];
    "/mnt/external/data-library".options = [ "nofail" "x-systemd.requires=zfs.target" ];
  };
}
