{ inputs, flake, withSystem, lib, ... }:
let
  nixosCommonModules = flake.lib.loaders.listFilesRecursively { src = "${flake}/shared-modules/nixos/common"; };

  nixosRoleModules =
    let
      rolesRoot = "${flake}/shared-modules/nixos/roles";
      availableModules = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir rolesRoot));
      mkRoleModules = role: { ${role} = flake.lib.loaders.listFilesRecursively { src = "${rolesRoot}/${role}"; }; };
    in
    lib.foldl' (acc: role: acc // (mkRoleModules role)) { } availableModules;

  loadMachine = name: flake.lib.loaders.listFilesRecursively { src = "${flake}/machines/${name}"; };

  overlays = import "${flake}/overlays/custom-packages.nix";

  mkModules =
    { name
    , withSharedModules ? true
    , roles ? [ ]
    , extraModules ? [ ]
    }: (loadMachine name)
      ++ lib.optionals withSharedModules nixosCommonModules
      ++ lib.optionals (roles != [ ]) (lib.flatten (lib.map (role: nixosRoleModules.${role}) roles))
      ++ extraModules;

  mkSystem =
    { name
    , system
    , roles ? [ ]
    , extraModules ? [ ]
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
            ++ (mkModules { inherit name withSharedModules roles extraModules; });
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
    , withSharedModules ? true
    , roles ? [ ]
    , extraModules ? [ ]
    , specialArgs ? { }
    }:
    {
      "${name}" = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = mkModules { inherit name withSharedModules roles extraModules; };
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
