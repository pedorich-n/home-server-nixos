#LINK - overlays/custom-packages.nix
{ inputs, overlays, lib, pkgs, pkgs-unstable, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      overlays.mc-monitor
      overlays.minecraft-modpack
      (_: prev:
        lib.optionalAttrs (!(prev.formats ? "xml")) {
          formats = prev.formats // {
            xml = pkgs-unstable.formats.xml;
          };
        })
    ];
  };

  _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
    inherit (pkgs) config overlays;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
