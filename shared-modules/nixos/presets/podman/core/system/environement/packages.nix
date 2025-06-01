{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.podman-tui
  ];
}
