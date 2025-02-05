{ lib, ... }: {
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

  systemd.services.podman.environment = {
    "LOGGING" = "--log-level=warn";
  };
}
