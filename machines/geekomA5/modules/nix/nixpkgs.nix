{ inputs, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
    ];
  };
}
