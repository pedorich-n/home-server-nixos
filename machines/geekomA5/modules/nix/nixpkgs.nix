{ inputs, config, overlays, ... }:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.poetry2nix.overlays.default
      overlays.minecraft-server-check
    ];
  };

  _module.args.pkgs-netdata-146 = import inputs.nixpkgs-netdata-146 {
    inherit (config.nixpkgs) system config;
  };
}
