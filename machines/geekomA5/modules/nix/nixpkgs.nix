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
        # FIXME: should probably be auto-fixed in 25.05
        (lib.optionalAttrs (!(prev.formats ? "xml")) {
          formats = prev.formats // {
            xml = pkgs-unstable.formats.xml;
          };
        })
      )
      (_: prev:
        (lib.optionalAttrs (!((prev.formats.ini { }) ? "lib")) {
          formats = prev.formats // {
            ini = pkgs-unstable.formats.ini;
          };
        })
      )
    ];
  };

  _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
