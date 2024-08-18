{ config, lib, pkgs, ... }:
let
  mkSystemdZfsMountTarget = pkgs.callPackage ./_systemd-zfs-mount-target.nix { inherit config; };
in
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

        # Properties of the zpool (zpool create -o <options>)
        options = {
          ashift = "12"; # Means 4KiB sector size
        };


        # NOTE https://github.com/nix-community/disko/issues/469#issuecomment-1944931386 for difference between `mountpoint` and `options.mountpoint`/`rootFsOptions.mountpoint`

        # Properties of the FS on the zpool (zfs set <options>)
        rootFsOptions = {
          compression = "zstd"; # ZSTD is based on LZ4 
          atime = "off"; # Disable Access Time 
          xattr = "sa"; # Store Linux attributes in inodes rather than files in hidden folders
          mountpoint = "/mnt/external"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
          "com.sun:auto-snapshot" = "false"; # Don't take snapshots of root
        };

        mountpoint = "/mnt/external"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko

        datasets = {
          immich = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/immich-library"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
              "com.sun:auto-snapshot" = "true";
            };
            mountpoint = "/mnt/external/immich-library"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko
          };

          paperless = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/paperless-library";
              "com.sun:auto-snapshot" = "true";
            };
            mountpoint = "/mnt/external/paperless-library";
          };
        };
      };
    };
  };

  # NOTE https://github.com/nix-community/disko/issues/581
  fileSystems = {
    "/mnt/external".options = [ "noauto" "nofail" ];
    "/mnt/external/immich-library".options = [ "noauto" "nofail" ];
    "/mnt/external/paperless-library".options = [ "noauto" "nofail" ];
  };


  systemd.services = lib.mkMerge [
    (mkSystemdZfsMountTarget { dataset = "external/immich"; })
    (mkSystemdZfsMountTarget { dataset = "external/paperless"; })
  ];
}
