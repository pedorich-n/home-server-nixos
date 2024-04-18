{ pkgs, ... }: {
  virtualisation.arion = {
    backend = "podman-socket";
  };

  environment.systemPackages = [ pkgs.arion ];
}
