{ config, lib, ... }: {
  config = lib.mkMerge [
    {
      virtualisation.podman = {
        enable = lib.mkDefault true;

        dockerSocket.enable = lib.mkDefault true;

        defaultNetwork.settings.dns_enabled = lib.mkDefault true;

        autoPrune = {
          enable = lib.mkDefault true;
          dates = lib.mkDefault "*-*-10 03:00:00"; # Every 10th of the month
          flags = lib.mkDefault [ "--all" ];
        };
      };
    }

    (lib.mkIf config.virtualisation.podman.enable {
      virtualisation.containers.containersConf.settings = {
        network = {
          # Runs DNS server on alternate port. See https://github.com/containers/common/blob/3e255710/docs/containers.conf.5.md?plain=1#L466-L471
          dns_bind_port = 5453;
        };
      };

      networking.firewall.interfaces."podman+" = {
        # Enables DNS resolution inside podman containers
        allowedUDPPorts = [
          53 # DNS
          5353 # mDNS
          5453 # container DNS
        ];
      };
    })
  ];
}
