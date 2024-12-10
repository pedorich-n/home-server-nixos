{ inputs, flake, withSystem, lib, ... }:
let
  sharedNixosModules = flake.lib.loaders.listFilesRecursively { src = "${flake}/shared-modules/nixos"; };
  loadMachine = name: flake.lib.loaders.listFilesRecursively { src = "${flake}/machines/${name}"; };

  overlays = import "${flake}/overlays/custom-packages.nix";

  mkSystem =
    { name
    , system
    , modules ? [ ]
    , withSharedModules ? true
    , specialArgs ? { }
    , enableDeploy ? true
    , deploySettings ? { }
    }:
    {
      "${name}" = (inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          [{ networking.hostName = lib.mkDefault name; }]
            ++ lib.optionals withSharedModules sharedNixosModules
            ++ modules
            ++ (loadMachine name);
        specialArgs = {
          inherit flake inputs system overlays;
        } // specialArgs;
      }) // {
        meta = {
          deploy = {
            enable = enableDeploy;
            settings = deploySettings;
          };
        };
      };
    };

  mkSystemIso =
    { name
    , system
    , withSharedModules ? false
    , modules ? [ ]
    , specialArgs ? { }
    }:
    {
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

  mkDeployNode = { name, nixosConfig }:
    {
      #TODO: figure out whether `system` is supposed to be the target system or the host
      "${name}" = withSystem nixosConfig.pkgs.system ({ deployPkgs, ... }: {
        hostname = name;
        interactiveSudo = false;
        magicRollback = true;
        remoteBuild = false;

        profiles = {
          system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos nixosConfig;
          } // nixosConfig.meta.deploy.settings;
        };
      });
    };
in
{
  flake.lib.builders = {
    inherit mkSystem mkSystemIso mkDeployNode;
  };
}
