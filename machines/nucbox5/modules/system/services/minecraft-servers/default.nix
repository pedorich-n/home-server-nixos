{
  services = {
    minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
    };

    minecraft-server-check = {
      enable = true;
      server-service = "minecraft-server-money-guys-4.service";
      tunnel-service = "playit.service";
      restart-timeout = 90;
    };
  };
}
