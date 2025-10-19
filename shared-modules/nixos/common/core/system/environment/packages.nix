{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Internet
    curl
    wget
    git

    # Tools
    vim # text editor
    util-linux # mount, umount, etc.
    htop # interactive process viewer
    jq # JSON processor
    tree # visualize directory structure
    lsof # list open files
  ];
}
