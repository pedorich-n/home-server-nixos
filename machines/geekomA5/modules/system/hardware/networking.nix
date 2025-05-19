{ config, lib, ... }: {
  options = {
    custom.networking.domain = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };

    custom.networking.domain-external = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };
  };

  config = {
    custom.networking = {
      domain = "server.lan";
      domain-external = config.custom.secrets.plaintext.variables.domain;
    };

    networking = {
      useNetworkd = true;
      networkmanager.enable = false;
      wireless.enable = false;

      hostId = "ac7dc50d"; # head -c 8 /etc/machine-id
    };

    systemd = {
      network = {
        enable = true;

        networks = {
          "10-uplink" = {
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
