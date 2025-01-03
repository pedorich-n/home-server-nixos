{ inputs, config, overlays, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.poetry2nix.overlays.default
      inputs.jinja2-renderer.overlays.default
      overlays.minecraft-server-check
    ];
  };

  _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
    inherit (config.nixpkgs) system config;
  };
}
