{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.minecraft-servers;
in
{
  ###### interface
  options = {
    custom.minecraft-servers = {
      enable = mkEnableOption "Minecraft Servers";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/ha-store/minecraft";

      servers = {
        "money-guys-1" = {
          enable = true;
          autoStart = true;
          openFirewall = true;

          package = pkgs.vanillaServers.vanilla-1_20_2;
          serverProperties = {
            server-port = 43000;
            difficulty = 2;
            enable-status = true;
            level-name = "the_best_1";
            motd = "NixOS Managed Server. Humans are not allowed.";
            max-players = 10;
          };
          jvmOpts = "-Xms1024M -Xmx4092M";
        };
      };
    };
  };
}
