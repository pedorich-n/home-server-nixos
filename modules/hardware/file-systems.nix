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
    "/mnt/debian" = {
      device = "/dev/disk/by-label/debian";
      fsType = "ext4";
    };
    "/mnt/ha-store" = {
      device = "/dev/disk/by-label/ha-store";
      options = [ "rw" "users" ];
      fsType = "ext4";
    };
  };
}
