{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Hardware
    lshw
    parted
    util-linux # cfdisk, fsck, mount, etc.

    # Utils
    rsync
  ];
}
