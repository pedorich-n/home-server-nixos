{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Internet
    curl
    wget
    gitMinimal

    # Tools
    dig # DNS lookup utility (dig, nslookup, etc.)
    dysk # disk usage analyzer (df, but nicer)
    vim # text editor
    util-linux # mount, umount, etc.
    htop # interactive process viewer
    jq # JSON processor
    tree # visualize directory structure
    lsof # list open files
  ];
}
