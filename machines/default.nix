{ inputs, self, withSystem }:
{ lib, ... }:
let
  myModules = import ../modules { inherit self; };
  sharedModules = lib.lists.flatten (builtins.attrValues myModules);

  loadMachine = name: self.lib.filesystem.list-modules { src = ./${name}; };

  mkSystem =
    { name
    , system
    , modules ? [ ]
    , specialArgs ? { }
    , enableDeploy ? true
    , deploySettings ? { }
    , ...
    }: (lib.mkMerge [
      {
        flake = {
          nixosConfigurations = {
            "${name}" = inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              modules =
                [{
                  networking.hostName = name;
                }]
                ++ sharedModules
                ++ modules
                ++ (loadMachine name);
              specialArgs = { inherit self inputs system; } // specialArgs;
            };
          };
        };
      }

      (lib.mkIf enableDeploy {
        perSystem = { lib, pkgs, deployPkgs, ... }: {
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

          apps = {
            "deploy-${name}".program = pkgs.writeShellScriptBin "deploy-${name}" ''
              ${lib.getExe deployPkgs.deploy-rs.deploy-rs} ${self} "$@"
            '';
          };

          checks = deployPkgs.deploy-rs.lib.deployChecks self.deploy;
        };

        flake = {
          deploy.nodes = withSystem system ({ deployPkgs, ... }: {
            "${name}" = {
              hostname = name;
              interactiveSudo = false;
              magicRollback = true;
              remoteBuild = false;

              profiles = {
                system = {
                  sshUser = "root";
                  user = "root";
                  path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.${name};
                } // deploySettings;
              };
            };
          });
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