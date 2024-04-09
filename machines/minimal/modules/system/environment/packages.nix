{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Internet
    curl
    gitMinimal
    wget
    rsync

    # Hardware
    lshw
    parted
    util-linux # cfdisk, fsck, mount, etc.

    # Tools
    htop
    jq
    tree
    vim
  ];
}
