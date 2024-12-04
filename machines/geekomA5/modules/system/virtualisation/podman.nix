{ pkgs-unstable, ... }: {
  virtualisation.podman = {
    package = pkgs-unstable.podman;
  };
}
