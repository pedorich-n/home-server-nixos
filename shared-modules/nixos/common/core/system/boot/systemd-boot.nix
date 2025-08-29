{ lib, config, ... }:
{
  boot.loader.systemd-boot = lib.mkIf config.boot.loader.systemd-boot.enable {
    configurationLimit = lib.mkDefault 10;
    editor = lib.mkDefault true; # Allows editing boot entries in case of emergency
  };
}
