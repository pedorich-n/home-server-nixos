{ inputs, flake, withSystem, lib }:
let
  sharedNixosModules = flake.lib.loaders.listModules { src = ../modules; };
  homeManagerNixosModules = [
    inputs.home-manager.nixosModules.default
    ../homes/default.nix
  ];

  loadMachine = name: flake.lib.loaders.listModules { src = ../machines/${name}; };

  overlays = import ../overlays/custom-packages.nix;

  mkSystem =
    { name
    , system
    , modules ? [ ]
    , withSharedModules ? true
    , withHmModules ? false
    , specialArgs ? { }
    , enableDeploy ? true
    , deploySettings ? { }
    }: (lib.mkMerge [
      {
        flake = {
          nixosConfigurations = {
            "${name}" = inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              modules =
                [{ networking.hostName = lib.mkDefault name; }]
                ++ lib.optionals withSharedModules sharedNixosModules
                ++ lib.optionals withHmModules homeManagerNixosModules
                ++ modules
                ++ (loadMachine name);
              specialArgs = {
                inherit flake inputs system overlays;
              } // specialArgs;
            };
          };
        };
      }

      (lib.mkIf enableDeploy {
        perSystem = { lib, pkgs, deployPkgs, ... }: {
          apps = {
            "deploy-${name}".program = pkgs.writeShellScriptBin "deploy-${name}" ''
              ${lib.getExe deployPkgs.deploy-rs.deploy-rs} "${flake}#${name}" "$@"
            '';
          };
        };

        flake = {
          deploy = {
            nodes = {
              #TODO: figure out whether `system` is supposed to be the target system or the host
              "${name}" = withSystem system ({ deployPkgs, ... }: {
                hostname = name;
                interactiveSudo = false;
                magicRollback = true;
                remoteBuild = false;

                profiles = {
                  system = {
                    sshUser = "root";
                    user = "root";
                    path = deployPkgs.deploy-rs.lib.activate.nixos flake.nixosConfigurations.${name};
                  } // deploySettings;
                };
              });
            };
          };
        };
      })
    ]);


  mkSystemIso =
    { name
    , system
    , withSharedModules ? false
    , modules ? [ ]
    , specialArgs ? { }
    }:
    {
      flake = {
        nixosConfigurations = {
          "${name}" = inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules =
              [{ networking.hostName = lib.mkForce "nixos"; }]
              ++ lib.optionals withSharedModules sharedNixosModules
              ++ modules
              ++ (loadMachine name);
            specialArgs = {
              inherit flake inputs system;
            } // specialArgs;
          };
        };
      };

      perSystem = { pkgs, ... }: {
        apps = {
          "build-iso-${name}".program = pkgs.writeShellScriptBin "build-iso-${name}" ''
            nix build "${flake}#nixosConfigurations.${name}.config.system.build.isoImage" "$@"
          '';
        };
      };
    };

in
{
  inherit mkSystem mkSystemIso;
}
