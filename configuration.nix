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

  time.timeZone = "Asia/Tokyo";

}
