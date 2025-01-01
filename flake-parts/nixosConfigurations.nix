{ flake, inputs, lib, ... }:
{
  flake.nixosConfigurations = lib.mkMerge [
    (flake.lib.builders.mkSystem {
      name = "geekomA5";
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.default
        inputs.airtable-telegram-bot.nixosModules.ngrok
        inputs.airtable-telegram-bot.nixosModules.calendar-loader
        inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler-cron
        inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.playit-nixos-module.nixosModules.default
        inputs.quadlet-nix.nixosModules.quadlet
      ];
      deploySettings = {
        activationTimeout = 600;
      };
    })

    (flake.lib.builders.mkSystemIso {
      name = "minimal";
      system = "x86_64-linux";
    })
  ];
}
