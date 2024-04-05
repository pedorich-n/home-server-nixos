{ inputs, system, self, ... }:
let
  settings = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.poetry2nix.overlays.default
      (import "${self}/overlays" inputs)
    ];
    config = {
      allowUnfree = true;
    };
  };
in
{
  _module.args.pkgs-unstable = import inputs.nixpkgs-unstable ({ inherit system; } // settings);

  nixpkgs = settings;
}
