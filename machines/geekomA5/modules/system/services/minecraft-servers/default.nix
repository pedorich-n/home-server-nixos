{ config, ... }: {
  services = {
    minecraft-servers = {
      enable = false;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
      managementSystem = {
        systemd-socket.enable = true;
      };
    };

    playit = {
      enable = true;
      secretPath = config.sops.secrets."playit/secret".path;
    };
  };
}
