{ minecraftLib, lib, config, pkgs, inputs, system, ... }:
let
  serverName = "money-guys-4";
in
{
  custom.networking.ports.tcp = lib.mkIf config.services.minecraft-servers.servers.${serverName}.enable {
    "minecraft-${serverName}-game" = { port = 43000; openFirewall = true; };
    "minecraft-${serverName}-metrics" = { port = 44040; openFirewall = true; };
    "minecraft-${serverName}-square-map" = { port = 44080; openFirewall = true; };
  };

  services.minecraft-servers.servers = {
    ${serverName} = {
      enable = true;
      autoStart = true;
      openFirewall = true;

      package = pkgs.fabricServers.fabric-1_20_1;
      serverProperties = {
        server-port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;
        difficulty = 2;
        level-name = "the_best_1";
        motd = "NixOS Managed Server. Humans are not allowed.";
        max-players = 10;
        enable-status = true;
        enforce-secure-profile = false;
        max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
        spawn-protection = 0;
      };
      jvmOpts = minecraftLib.aikarFlagsWith "5120M";

      symlinks = {
        "server-icon.png" = ./icon.png;
      } // (minecraftLib.mkConsoleAccessSymlink serverName)
      // (minecraftLib.mkPackwizModsSymlinks inputs.fabric-modpack.packages.${system}.packwiz-server);
    };
  };
}
