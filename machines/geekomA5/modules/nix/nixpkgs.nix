#LINK - overlays/custom-packages.nix
{ inputs, overlays, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      overlays.mc-monitor
      overlays.minecraft-modpack
    ];
  };
}
