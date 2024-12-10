{ lib, config, ... }: {
  boot.loader.grub = lib.mkIf config.boot.loader.grub.enable {
    devices = [ "nodev" ];
    efiSupport = true;
    useOSProber = true;
    configurationLimit = lib.mkDefault 5;
  };
}
