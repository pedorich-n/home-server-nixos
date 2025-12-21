{ inputs, ... }:
{
  flake.builders.nixosConfigurations = {
    geekomA5 = {
      withPresets =
        presets: with presets; [
          headless
          home-manager
          podman
          ssh
          systemd-notifications
        ];
      extraModules = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.default
        inputs.airtable-telegram-bot.nixosModules.ngrok
        inputs.airtable-telegram-bot.nixosModules.calendar-loader
        inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler-cron
        inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
        inputs.nix-minecraft.nixosModules.minecraft-servers
        inputs.playit-nixos-module.nixosModules.default
        inputs.quadlet-nix.nixosModules.quadlet
        inputs.copyparty.nixosModules.default
        inputs.geekdo-sync.nixosModules.default
      ];
      deploySettings = {
        activationTimeout = 600;
      };
    };

    minimal = {
      withPresets =
        presets: with presets; [
          ssh
          headless
        ];
      enableDeploy = false;
    };
  };
}
