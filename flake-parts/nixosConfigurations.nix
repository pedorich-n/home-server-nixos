{ flake, withSystem, ... }:
{ inputs, lib, ... }:
let
  sharedNixosModules = flake.lib.loaders.listModules { src = ../modules; };
  homeManagerNixosModules = [
    inputs.home-manager.nixosModules.default
    ../homes/default.nix
  ];

  builders = import ../machines/builders.nix { inherit inputs flake withSystem lib; };

  overlays = import ../overlays/custom-packages.nix;
in
lib.mkMerge [
  (builders.mkSystem {
    name = "geekomA5";
    system = "x86_64-linux";
    modules = sharedNixosModules ++ homeManagerNixosModules ++ [
      inputs.arion.nixosModules.arion
      inputs.disko.nixosModules.disko
      inputs.airtable-telegram-bot.nixosModules.ngrok
      inputs.airtable-telegram-bot.nixosModules.calendar-loader
      inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler-cron
      inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.playit-nixos-module.nixosModules.default
    ];

    specialArgs = {
      inherit overlays;
    };

    enableDeploy = true;
  })

  (builders.mkSystemIso {
    name = "minimal";
    system = "x86_64-linux";
  })
]
