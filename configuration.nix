{ pkgs, inputs, ... }: {
  imports = [
    ./modules/hardware
    ./modules/services
    ./modules/packages.nix
    ./modules/virtualisation.nix
    ./modules/nix.nix
    ./modules/users.nix
    ./modules/secrets.nix
    ./modules/custom/mutable-files
    ./modules/home-automation/arion-compose.nix
  ];

  system.stateVersion = "23.05";

  #nixpkgs.overlays = [ (import ./overlays inputs) ];

  # virtualisation.docker = {
  #   enable = true;
  # };

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
    # environment.mutable-files = {
    #   "/mnt/ha-store/test".source = ./folders_test/source;
    # };
  };


  # programs = {
  #   zsh.enable = true;
  # };

  time.timeZone = "Asia/Tokyo";

}
