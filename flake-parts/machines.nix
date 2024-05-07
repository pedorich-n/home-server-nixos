{ flake, withSystem, ... }:
{ inputs, lib, ... }:
let
  myModules = import ../modules { inherit flake; };
  sharedModules = lib.lists.flatten (builtins.attrValues myModules);

  builders = import ../machines/builders.nix { inherit inputs flake withSystem lib; };

  overlays = import ../overlays/custom-packages.nix;
in
lib.mkMerge [
  {
    # Static global config, that should always be present

    perSystem = { system, pkgs, deployPkgs, ... }: {
      _module.args = {
        # From https://github.com/serokell/deploy-rs/blob/88b3059b020da69cbe16526b8d639bd5e0b51c8b/README.md?plain=1#L89-L114
        deployPkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.deploy-rs.overlays.default
            (_: prev: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                lib = prev.deploy-rs.lib;
              };
            })
          ];
        };
      };

      # checks = lib.mkIf (flake.deploy or { } != { }) (deployPkgs.deploy-rs.lib.deployChecks flake.deploy);
    };
  }

  (builders.mkSystem {
    name = "nucbox5";
    system = "x86_64-linux";
    modules = sharedModules ++ [
      inputs.arion.nixosModules.arion
      inputs.airtable-telegram-bot.nixosModules.ngrok
      inputs.airtable-telegram-bot.nixosModules.calendar-loader
      inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler
      inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
      inputs.nixos-mutable-files-manager.nixosModules.default
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.playit-nixos-module.nixosModules.default
    ];

    specialArgs = {
      inherit overlays;
    };

    enableDeploy = true;
  })

  (builders.mkSystem {
    name = "geekomA5";
    system = "x86_64-linux";
    modules = sharedModules ++ [
      inputs.arion.nixosModules.arion
      inputs.disko.nixosModules.disko
      inputs.airtable-telegram-bot.nixosModules.ngrok
      inputs.airtable-telegram-bot.nixosModules.calendar-loader
      inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler-cron
      inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
      inputs.nixos-mutable-files-manager.nixosModules.default
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
