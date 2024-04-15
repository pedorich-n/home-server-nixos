{ inputs, self, withSystem, lib }:
let
  loadMachine = name: self.lib.list-modules { src = ./${name}; };

  mkSystem =
    { name
    , system
    , modules ? [ ]
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
                [{
                  networking.hostName = lib.mkDefault name;
                }]
                ++ modules
                ++ (loadMachine name);
              specialArgs = { inherit self inputs system; } // specialArgs;
            };
          };
        };
      }

      (lib.mkIf enableDeploy {
        perSystem = { lib, pkgs, deployPkgs, ... }: {
          apps = {
            "deploy-${name}".program = pkgs.writeShellScriptBin "deploy-${name}" ''
              ${lib.getExe deployPkgs.deploy-rs.deploy-rs} "${self}#${name}" "$@"
            '';
          };
        };

        flake = {
          deploy = {
            nodes = {
              "${name}" = withSystem system ({ deployPkgs, ... }: {
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
              });
            };
          };
        };
      })
    ]);


  mkSystemIso = { name, system, ... } @ args:
    let
      extraArgs = builtins.removeAttrs args [ "name" "system" "enableDeploy" ];
    in
    lib.mkMerge [
      (mkSystem ({
        inherit name system;
        enableDeploy = false;
        modules = [{ networking.hostName = lib.mkForce "nixos"; }];
      } // extraArgs))
      {
        perSystem = { pkgs, ... }: {
          apps = {
            "build-iso-${name}".program = pkgs.writeShellScriptBin "build-iso-${name}" ''
              ${lib.getExe pkgs.nix} build "${self}#nixosConfigurations.${name}.config.system.build.isoImage" "$@"
            '';
          };
        };
      }
    ];
in
{
  inherit mkSystem mkSystemIso;
}
