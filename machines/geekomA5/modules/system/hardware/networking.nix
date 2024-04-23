{
  custom.networking.domain = "server.lan";

  networking = {
    useNetworkd = true;
    networkmanager.enable = false;
    wireless.enable = false;
  };

  systemd.network = {
    enable = true;

    networks = {
      "10-eth" = {
        name = "enp2s0";

        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };

  services.resolved = {
    enable = true;
  };
}
