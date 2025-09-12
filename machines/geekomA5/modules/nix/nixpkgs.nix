#LINK - overlays/custom-packages.nix
{
  inputs,
  overlays,
  pkgs,
  ...
}:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      inputs.copyparty.overlays.default
      overlays.github-app-installation-token
      overlays.cockpit-plugins
      overlays.minecraft-modpacks
      overlays.lldap-bootstrap
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };

  _module.args.pkgs-dashy = import inputs.nixpkgs-dashy {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
