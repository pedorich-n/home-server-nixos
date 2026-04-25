#LINK - overlays/custom-packages.nix
{
  inputs,
  custom-overlays,
  ...
}:
{
  nixpkgs = {
    overlays = [
      inputs.nix-minecraft.overlays.default
      inputs.playit-nixos-module.overlays.default
      inputs.copyparty.overlays.default
      custom-overlays
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };
}
