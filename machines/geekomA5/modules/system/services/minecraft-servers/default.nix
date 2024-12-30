{ config, pkgs-unstable, ... }:
{
  services = {
    minecraft-servers = {
      enable = false;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
    };

    playit = {
      enable = false;
      secretPath = config.age.secrets.playit_secret.path;
    };
  };

  custom.services = {
    minecraft-server-check = {
      enable = false;
      package = pkgs-unstable.minecraft-server-check;
      configPath = config.age.secrets.server_check_config.path;
      tunnel-service = "playit.service";
      restart-timeout = 90;
    };
  };
}
