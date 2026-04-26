#LINK - overlays/custom-nixos-packages.nix
{
  inputs,
  custom-packages-overlay,
  ...
}:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      inputs.copyparty.overlays.default
      custom-packages-overlay
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };
}
