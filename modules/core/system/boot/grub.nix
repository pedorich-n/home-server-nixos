{ lib, ... }: {
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 5;

      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
        configurationLimit = lib.mkDefault 5;
      };
    };
  };
}
