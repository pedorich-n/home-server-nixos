{ inputs, flake, config, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.poetry2nix.overlays.default
      (_: prev: {
        minecraft-server-check = prev.callPackage "${flake}/pkgs/minecraft-server-check" { };
        render-jinja-template = prev.callPackage "${flake}/pkgs/render-jinja-template" { };
      })
    ];
  };

  _module.args.pkgs-netdata-45 = import inputs.nixpkgs-netdata-45 {
    inherit (config.nixpkgs) system config;
  };
}
