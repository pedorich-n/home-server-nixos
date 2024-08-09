{ inputs, config, overlays, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.poetry2nix.overlays.default
      overlays.minecraft-server-check
      overlays.jinja-renderer
      overlays.jinja-render
    ];
  };

  _module.args.pkgs-netdata-146 = import inputs.nixpkgs-netdata-146 {
    inherit (config.nixpkgs) system config;
  };
}
