{ config, ... }: {
  services = {
    # minecraft-servers = {
    #   enable = false;
    #   openFirewall = true;
    #   eula = true;
    #   dataDir = "/mnt/store/minecraft";
    # };

    playit = {
      enable = true;
      secretPath = config.sops.secrets."playit/secret".path;
    };
  };
}
