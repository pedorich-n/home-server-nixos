{ inputs, ... }: {
  nixpkgs = {
    overlays = [ inputs.nix-minecraft.overlay ];
    config = {
      allowUnfree = true;
    };
  };
}
