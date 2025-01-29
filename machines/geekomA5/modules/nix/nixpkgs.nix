{ inputs, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
      inputs.jinja2-renderer.overlays.default
    ];
  };
}
