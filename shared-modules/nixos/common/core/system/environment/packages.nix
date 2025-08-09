{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Internet
    curl
    wget
    git

    # Tools
    vim
    util-linux # mount, umount, etc.
    htop
    jq
    tree
  ];
}
