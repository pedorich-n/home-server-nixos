{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
    htop
    jq
    lshw
    parted
    rsync
    tree
    vim
    wget
  ];
}
