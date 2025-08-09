{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.home-manager-config.overlays.default
  ];
}
