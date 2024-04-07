{ pkgs, ... }: {
  virtualisation = {
    vmVariant = {
      virtualisation = {
        cores = 8;
        memorySize = 4096;
        diskSize = 7224;
      };
    };

    podman = {
      enable = true;

      dockerCompat = true;
      dockerSocket.enable = true;

      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = [
    pkgs.podman-compose
  ];
}
