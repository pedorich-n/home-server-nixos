{ inputs, ... }: {
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlay
      inputs.rust-overlay.overlays.default
      (import ../overlays inputs)
    ];
    config = {
      allowUnfree = true;
    };
  };
}
