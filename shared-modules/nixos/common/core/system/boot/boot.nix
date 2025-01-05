{ modulesPath, lib, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 5;
    };
  };
}
