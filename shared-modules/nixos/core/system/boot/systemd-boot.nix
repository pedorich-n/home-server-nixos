{ lib, config, ... }: {
  boot.loader.systemd-boot = lib.mkIf config.boot.loader.systemd-boot.enable {
    configurationLimit = lib.mkDefault 10;
    editor = false;
  };
}
