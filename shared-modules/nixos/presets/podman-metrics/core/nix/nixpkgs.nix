#LINK - overlays/custom-packages.nix
{ overlays, ... }: {
  nixpkgs = {
    overlays = [
      overlays.prometheus-podman-exporter
    ];
  };
}
