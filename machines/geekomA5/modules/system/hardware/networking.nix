{
  custom.networking.domain = "server.lan";

  networking = {
    useNetworkd = true;
    networkmanager.enable = false;
    wireless.enable = false;

    hostId = "ac7dc50d"; # head -c 8 /etc/machine-id
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
