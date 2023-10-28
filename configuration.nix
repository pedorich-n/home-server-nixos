{
  imports = [
    ./modules/hardware
    ./modules/services
    ./modules/packages.nix
    ./modules/virtualisation.nix
    ./modules/nix.nix
    ./modules/nixpkgs.nix
    ./modules/users.nix
    ./modules/secrets.nix
    ./modules/switch-diff.nix
    ./modules/home-automation
  ];

  system.stateVersion = "23.05";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "en_GB.UTF-8";
      LC_IDENTIFICATION = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
      LC_MONETARY = "en_GB.UTF-8";
      LC_NAME = "en_GB.UTF-8";
      LC_NUMERIC = "en_GB.UTF-8";
      LC_PAPER = "en_GB.UTF-8";
      LC_TELEPHONE = "en_GB.UTF-8";
      LC_TIME = "en_GB.UTF-8";
    };

  };

  custom = {
    gui.enable = false;
    minecraft-servers.enable = true;
  };

  time.timeZone = "Asia/Tokyo";

}
