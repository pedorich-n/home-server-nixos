{ config, pkgs-unstable, ... }:
let
  portsCfg = config.custom.networking.ports;
in
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
      secretPath = config.age.secrets.playit_secret_nucbox.path;
      runOverride = {
        "aeadb59e-5a44-49cb-aaca-be17946e0e04".port = portsCfg.tcp.minecraft-money-guys-4-game.port;
        "c50850ff-06fb-4c83-b9e4-4580db92d4be".port = portsCfg.tcp.minecraft-money-guys-4-square-map.port;
      };
    };
  };

  custom.services = {
    minecraft-server-check = {
      enable = false;
      package = pkgs-unstable.minecraft-server-check;
      configPath = config.age.secrets.server_check_config.path;
      server-service = "minecraft-server-money-guys-4.service";
      tunnel-service = "playit.service";
      restart-timeout = 90;
    };
  };
}
