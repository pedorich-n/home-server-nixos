{ pkgs, lib, ... }: {
  virtualisation = {
    vmVariant = {
      virtualisation = {
        cores = lib.mkDefault 8;
        memorySize = lib.mkDefault 4096;
        diskSize = lib.mkDefault 7224;
      };
    };

    podman = {
      enable = lib.mkDefault true;

      dockerCompat = lib.mkDefault true;
      dockerSocket.enable = lib.mkDefault true;

      defaultNetwork.settings.dns_enabled = lib.mkDefault true;
    };
  };

  environment.systemPackages = [
    pkgs.podman-compose
  ];
}
