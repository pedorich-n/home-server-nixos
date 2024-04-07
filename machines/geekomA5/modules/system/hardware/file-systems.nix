{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    "/mnt/store" = {
      device = "/dev/disk/by-label/store";
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };
}
