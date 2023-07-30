{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    arion
    bat
    curl
    firefox
    git
    htop
    vim
  ];
}
