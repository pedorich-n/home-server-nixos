{ lib, ... }:
{
  flake.overlays = {
    # TODO: come up/find a function to load all overlays from a directory, similar to how it's done for modules with importApply
    default = import ../overlays/custom-packages.nix { inherit lib; };
  };
}
