{ inputs, ... }: {
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlay
      inputs.rust-overlay.overlays.default
      inputs.poetry2nix.overlays.default
      (import ../overlays inputs)
    ];
    config = {
      allowUnfree = true;
    };
  };
}
