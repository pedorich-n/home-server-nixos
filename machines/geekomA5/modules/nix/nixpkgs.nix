#LINK - overlays/custom-packages.nix
{
  inputs,
  overlays,
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
      overlays.dashy-ui
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };
}
