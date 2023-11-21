{ minecraftLib, pkgs, inputs, system, config, ... }:
let
  serverName = "money-guys-3";
in
{
  custom.shared-config.ports.minecraft-money-guys-3.tcp = {
    game = { port = 43000; openFirewall = true; };
    metrics = { port = 44040; openFirewall = true; };
    square-map = { port = 44080; openFirewall = true; };
  };

  services.minecraft-servers.servers = {
    ${serverName} = {
      enable = true;
      autoStart = true;
      openFirewall = true;

      package = pkgs.fabricServers.fabric-1_20_1;
      serverProperties = {
        server-port = config.custom.shared-config.ports.minecraft-money-guys-2.tcp.game.port;
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
