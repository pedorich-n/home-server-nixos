{ inputs, config, lib, pkgs, ... }: {

  # TODO - remove this once https://github.com/NixOS/nixpkgs/pull/305803 makes it to stable
  disabledModules = [ "virtualisation/podman/default.nix" ];

  imports = [ "${inputs.nixpkgs-podman-module}/nixos/modules/virtualisation/podman/default.nix" ];

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
