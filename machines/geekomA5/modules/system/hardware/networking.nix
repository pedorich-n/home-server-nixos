{ lib, ... }: {
  options = {
    custom.networking.domain = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };
  };

  config = {
    custom.networking.domain = "server.lan";

    networking = {
      useNetworkd = true;
      networkmanager.enable = false;
      wireless.enable = false;

      hostId = "ac7dc50d"; # head -c 8 /etc/machine-id
    };

    systemd = {
      services."systemd-networkd".environment = {
        SYSTEMD_LOG_LEVEL = "debug";
      };

      network = {
        enable = true;

        networks = {
          "10-eth" = {
            name = "enp2s0";

            networkConfig = {
              DHCP = "yes";
              IgnoreCarrierLoss = "10m";
            };
          };
        };
      };
    };

    services.resolved = {
      enable = true;
    };
  };
}
