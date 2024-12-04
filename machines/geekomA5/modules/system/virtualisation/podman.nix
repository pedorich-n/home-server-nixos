{ pkgs-unstable, ... }: {
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    package = pkgs-unstable.podman;
  };
}
