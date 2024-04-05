{ inputs, self }:
{ lib, ... }:
let
  myModulesPath = ../modules;

  coreModules = "${myModulesPath}/core";
  customModules = "${myModulesPath}/custom";

  sharedModules = [
    coreModules
    customModules
  ];


  mkSystem =
    { name
    , system
    , modules ? [ ]
    , specialArgs ? { }
    , enableDeploy ? true
    , ...
    }: (lib.mkMerge [
      {
        flake = {
          nixosConfigurations = {
            "${name}" = inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              modules = sharedModules ++ modules ++ [ ./${name} ];
              specialArgs = { inherit inputs system self; } // specialArgs;
            };
          };
        };
      }
      (lib.mkIf enableDeploy {
        perSystem = { lib, pkgs, ... }: {
          apps = {
            "deploy-${name}".program = pkgs.writeShellScriptBin "deploy-${name}" ''
              ${lib.getExe pkgs.deploy-rs} ${self} "$@"
            '';
          };
        };

        flake = {
          deploy.nodes = {
            "${name}" = {
              hostname = name;
              interactiveSudo = false;
              magicRollback = true;
              remoteBuild = false;

              profiles = {
                system = {
                  sshUser = "root";
                  user = "root";
                  path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
                };
              };
            };
          };
        };
      })
    ]);

in
lib.mkMerge [
  (mkSystem {
    name = "nucbox5";
    system = "x86_64-linux";
    modules = [
      inputs.arion.nixosModules.arion
      inputs.agenix.nixosModules.default
      inputs.airtable-telegram-bot.nixosModules.ngrok
      inputs.airtable-telegram-bot.nixosModules.calendar-loader
      inputs.airtable-telegram-bot.nixosModules.calendar-loader-scheduler
      inputs.airtable-telegram-bot.nixosModules.telegram-lessons-bot
      inputs.nixos-mutable-files-manager.nixosModules.default
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.playit-nixos-module.nixosModules.default
    ];

    enableDeploy = true;
  })
]
