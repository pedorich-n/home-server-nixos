{ inputs, self, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.poetry2nix.overlays.default
      (_: prev: {
        minecraft-server-check = prev.callPackage "${self}/pkgs/minecraft-server-check" { };
      })
    ];
  };
}
