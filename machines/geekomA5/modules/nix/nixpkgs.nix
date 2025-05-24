#LINK - overlays/custom-packages.nix
{ inputs, overlays, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      overlays.cockpit-plugins
      overlays.minecraft-modpacks
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };
}
