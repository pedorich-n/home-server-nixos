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

    # TODO: migrate to some other S3 provider
    config.permittedInsecurePackages = [
      "minio-2025-10-15T17-29-55Z"
    ];
  };

  # _module.args.pkgs-netdata = import inputs.nixpkgs-netdata {
  #   inherit (pkgs) config;
  #   inherit (pkgs.stdenv.hostPlatform) system;
  # };
}
