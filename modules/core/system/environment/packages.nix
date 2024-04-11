{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Internet
    curl
    wget
    git

    # Tools
    vim
    util-linux # mount, umount, etc.
    bashmount # TUI for mounting USB
    htop
    jq
    tree
    nix-tree
  ];
}
