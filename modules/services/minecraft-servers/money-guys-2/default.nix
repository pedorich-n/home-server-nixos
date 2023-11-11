{ minecraftLib, pkgs, inputs, system, ... }:
let
  serverName = "money-guys-2";
in
{
  networking.firewall = {
    allowedTCPPorts = [
      44040 # Metrics Exporter
      44080 # SquareMap
      44081 # Create TrackMap
    ];
  };

  services.minecraft-servers.servers = {
    ${serverName} = {
      enable = true;
      autoStart = true;
      openFirewall = true;

      package = pkgs.fabricServers.fabric-1_20_1;
      serverProperties = {
        server-port = 43000;
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
        "server-icon.png" = ./server-icon.png;
      } // (minecraftLib.mkConsoleAccessSymlink serverName)
      // (minecraftLib.mkPackwizModsSymlinks inputs.fabric-modpack.packages.${system}.packwiz-server);
    };
  };
}
