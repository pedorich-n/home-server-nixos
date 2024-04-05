{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./boot.nix
    ./file-systems.nix
    ./networking.nix
    ./udev.nix
  ];
}
