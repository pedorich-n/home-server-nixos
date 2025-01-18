{ inputs, pkgs, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.poetry2nix.overlays.default
      inputs.jinja2-renderer.overlays.default
    ];
  };

  _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
    inherit (pkgs) config overlays;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
