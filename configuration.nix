{
  imports = [
    ./modules/custom
    ./modules/hardware
    ./modules/services

    ./modules/nix.nix
    ./modules/nixpkgs.nix
    ./modules/packages.nix
    ./modules/secrets.nix
    ./modules/switch-diff.nix
    ./modules/users.nix
    ./modules/virtualisation.nix
  ];

  system.stateVersion = "23.05";

}
