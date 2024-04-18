{ config, lib, pkgs, ... }: {

  config = lib.mkMerge [
    {
      virtualisation.podman = {
        enable = lib.mkDefault true;

        dockerCompat = lib.mkDefault true;
        dockerSocket.enable = lib.mkDefault true;

        defaultNetwork.settings.dns_enabled = lib.mkDefault true;
      };
    }

    (lib.mkIf config.virtualisation.podman.enable {
      environment.systemPackages = [
        pkgs.podman-compose
      ];

      networking.firewall.interfaces."podman+" = {
        # Enables DNS resolution inside podman containers
        allowedUDPPorts = [ 53 5353 ];
      };
    })
  ];
}
