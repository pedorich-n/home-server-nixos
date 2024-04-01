{ config, ... }:
let
  portsCfg = config.custom.shared-config.ports;
in
{
  services.playit = {
    enable = true;
    user = "playit";
    group = "playit";
    secretPath = config.age.secrets.playit_secret.path;
    runOverride = {
      "aeadb59e-5a44-49cb-aaca-be17946e0e04".port = portsCfg.tcp.minecraft-money-guys-4-game.port;
      "c50850ff-06fb-4c83-b9e4-4580db92d4be".port = portsCfg.tcp.minecraft-money-guys-4-square-map.port;
    };
  };
}
