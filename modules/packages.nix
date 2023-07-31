{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    arion
    bat
    curl
    git
    htop
    vim
  ];
}
