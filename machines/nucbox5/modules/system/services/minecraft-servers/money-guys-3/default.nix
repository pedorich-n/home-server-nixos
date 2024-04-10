{ minecraftLib, lib, config, pkgs, inputs, system, ... }:
let
  serverName = "money-guys-3";
in
{
  custom.networking.ports.tcp = lib.mkIf config.services.minecraft-servers.servers.${serverName}.enable {
    "minecraft-${serverName}-game" = { port = 43000; openFirewall = true; };
    "minecraft-${serverName}-metrics" = { port = 44040; openFirewall = true; };
    "minecraft-${serverName}-square-map".port = 44080;
  };

  services.minecraft-servers.servers = {
    ${serverName} = {
      enable = false;
      autoStart = true;
      openFirewall = true;

      package = pkgs.fabricServers.fabric-1_20_1;
      serverProperties = {
        server-port = config.custom.networking.ports.tcp.minecraft-money-guys-3-game.port;
        difficulty = 2;
        level-name = "the_best_1";
        motd = "NixOS Managed Server. Humans are not allowed.";
        max-players = 10;
        enable-status = true;
        enforce-secure-profile = false;
        max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
        spawn-protection = 0;
      };
      jvmOpts = minecraftLib.aikarFlagsWith "4096M";

      symlinks = {
        "server-icon.png" = ../default-server-icon.png;
      } // (minecraftLib.mkConsoleAccessSymlink serverName)
      // (minecraftLib.mkPackwizModsSymlinks inputs.fabric-modpack.packages.${system}.packwiz-server);
    };
  };
}
