{ config, lib, pkgs, ... }:
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
          "org.openzfs.systemd:nofail" = "on"; # Don't halt boot if fails to mount the FS
        };

        mountpoint = "/mnt/external"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko

        datasets = {
          immich = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/immich-library"; # ZFS prop: https://openzfs.github.io/openzfs-docs/man/v2.2/7/zfsprops.7.html#mountpoint
              "com.sun:auto-snapshot" = "true";
              "org.openzfs.systemd:nofail" = "on"; # Don't halt boot if fails to mount the FS
            };
            mountpoint = "/mnt/external/immich-library"; # fstab mountpoint, ideally should be removed, but it's not currently possible with disko
          };

          paperless = {
            type = "zfs_fs";
            options = {
              mountpoint = "/mnt/external/paperless-library";
              "com.sun:auto-snapshot" = "true";
              "org.openzfs.systemd:nofail" = "on"; # Don't halt boot if fails to mount the FS
            };
            mountpoint = "/mnt/external/paperless-library";
          };
        };
      };
    };
  };

  # NOTE https://github.com/nix-community/disko/issues/581
  fileSystems = {
    "/mnt/external".options = [ "noauto" ];
    "/mnt/external/immich-library".options = [ "noauto" ];
    "/mnt/external/paperless-library".options = [ "noauto" ];
  };

  # systemd.services = lib.mkMerge [
  #   (mkSystemdZfsMountTarget { dataset = "external/immich"; })
  #   (mkSystemdZfsMountTarget { dataset = "external/paperless"; })
  # ];

  #SECTION - zfs-mount-generator

  #NOTE this doesn't currently work with disko, because it sets the `fileSystems` automatically, and that causes NixOS
  # to generate a fstab entry and a fstab systemd mount unit with the same name as zfs-mount-generator does.
  # I think fstab's generated unit takes precedence over the zfs' one. 
  # To make this setup work we need to exclude zfs from `fileSystems` and rely only on systemd.
  # See https://github.com/nix-community/disko/issues/581


  #NOTE zfs-mount-generator is not supported natively by NixOS, so we need to enable it and make sure all the requirements are met.
  # See https://github.com/NixOS/nixpkgs/issues/62644#issuecomment-1479523469
  # See https://github.com/Shados/nix-config-shared/blob/a70d3cff3ccb30b73747bd6bb87b5119bfd13029/nixos/system/zfs.nix#L67-L96

  environment.etc."zfs/zed.d/history_event-zfs-list-cacher.sh".source = "${config.boot.zfs.package}/etc/zfs/zed.d/history_event-zfs-list-cacher.sh";

  systemd.tmpfiles.rules = [
    #Type Path                    pool-name    Mode User Group Age Argument
    "f    /etc/zfs/zfs-list.cache/external     0644 root root  -   -"
  ];

  # zfs-mount-generator needs a diffutils, but because `services.zfs.zed.settings.PATH` is a string, we need to completly override it,
  # copying everything from the original list plus the diffutils
  services.zfs.zed.settings.PATH = lib.mkForce (lib.makeBinPath [
    pkgs.diffutils
    config.boot.zfs.package
    pkgs.coreutils
    pkgs.curl
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.nettools
    pkgs.util-linux
  ]);

  systemd = {
    generators."zfs-mount-generator" = "${config.boot.zfs.package}/lib/systemd/system-generator/zfs-mount-generator";
    services.zfs-mount.enable = false;
  };

  #!SECTION - zfs-mount-generator
}
