{ inputs, ... }:
let
  settings = {
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
in
{
  _module.args.nixpkgs-unstable = import inputs.nixpkgs-unstable ({ system = builtins.currentSystem; } // settings);

  nixpkgs = settings;
}
