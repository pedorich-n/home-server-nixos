{ config, lib, ... }:
{
  options = {
    custom.networking.domain = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };
  };

  config = {
    custom.networking = {
      domain = config.custom.secrets.plaintext.variables.domain;
    };

    networking = {
      useNetworkd = true;
      networkmanager.enable = false;
      wireless.enable = false;
      enableIPv6 = false;

      hostId = "ac7dc50d"; # head -c 8 /etc/machine-id
    };

    systemd = {
      network = {
        enable = true;

        networks = {
          "10-uplink" = {
            name = "enp2s0";

            networkConfig = {
              DHCP = true;
              IgnoreCarrierLoss = "10m";
            };
          };

          "10-wireless" = {
            name = "wlp3s0";

            linkConfig = {
              # Don't use WiFi on this machine
              Unmanaged = true;
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
