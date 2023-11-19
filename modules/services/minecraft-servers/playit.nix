{ config, ... }:
let
  portsCfg = config.custom.shared-config.ports;
in
{
  services.playit = {
    enable = true;
    user = "playit";
    group = "playit";
    secretPath = config.age.secrets.playit-secret.path;
    runOverride = {
      # "62884177-5592-45a9-9662-492b42407881".port = 43000; # Also 43001, 43002
      # "c0310a34-1ed3-4c6d-94f8-739c1d6b2f0f".port = 44080; # Also 44081, 44082
      "aeadb59e-5a44-49cb-aaca-be17946e0e04".port = portsCfg.minecraft-money-guys-2.udp.game.port;
      "c50850ff-06fb-4c83-b9e4-4580db92d4be".port = portsCfg.minecraft-money-guys-2.tcp.square-map.port;
      "5c751f9e-e95b-4cce-8718-db58a358c160".port = portsCfg.minecraft-money-guys-2.tcp.tracks-map.port;
    };
  };
}
