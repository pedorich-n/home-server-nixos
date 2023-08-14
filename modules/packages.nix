{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bat
    curl
    git
    htop
    jq
    tree
    vim
  ];
}
