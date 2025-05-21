{ config, ... }: {
  custom.minecraft-servers.check.enable = false;

  services = {
    minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
      managementSystem = {
        systemd-socket.enable = true;
      };
    };

    playit = {
      enable = false;
      secretPath = config.sops.secrets."playit/secret".path;
    };
  };
}
