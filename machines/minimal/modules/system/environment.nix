{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Hardware inventory / partitioning
    lshw
    parted

    # Filesystems
    lvm2 # Logical Volume Manager
    dosfstools # FAT/VFAT
    e2fsprogs # ext2/ext3/ext4
    btrfs-progs # btrfs

    # Transfer
    rsync
    curl
    wget

    # Diagnostics (handy for emergency recovery / network debugging)
    htop
    bind # dig, host, nslookup
    nmap
  ];
}
