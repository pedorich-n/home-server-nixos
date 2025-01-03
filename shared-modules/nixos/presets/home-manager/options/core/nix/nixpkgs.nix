{ inputs, ... }: {
  nixpkgs.overlays = [
    inputs.personal-home-manager.overlays.default
  ];
}
