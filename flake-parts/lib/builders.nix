{ inputs, flake, withSystem, lib, ... }:
let
  nixosCommonModules = flake.lib.loaders.listFilesRecursively { src = "${flake}/shared-modules/nixos/common"; };

  nixosPresetModules =
    let
      rolesRoot = "${flake}/shared-modules/nixos/presets";
      availablePresets = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir rolesRoot));
      mkPresetModules = role: { ${role} = flake.lib.loaders.listFilesRecursively { src = "${rolesRoot}/${role}"; }; };
    in
    lib.foldl' (acc: role: acc // (mkPresetModules role)) { } availablePresets;

  loadMachine = name: flake.lib.loaders.listFilesRecursively { src = "${flake}/machines/${name}"; };

  overlays = import "${flake}/overlays/custom-packages.nix";

  mkModules =
    { name
    , withSharedModules ? true
    , presets ? [ ]
    , extraModules ? [ ]
    }: (loadMachine name)
      ++ lib.optionals withSharedModules nixosCommonModules
      ++ lib.optionals (presets != [ ]) (lib.flatten (lib.map (role: nixosPresetModules.${role}) presets))
      ++ extraModules;

  mkSystem =
    { name
    , presets ? [ ]
    , extraModules ? [ ]
    , withSharedModules ? true
    , specialArgs ? { }
    , enableDeploy ? true
    , deploySettings ? { }
    }:
    {
      "${name}" = (inputs.nixpkgs.lib.nixosSystem {
        modules =
          [{ networking.hostName = lib.mkDefault name; }]
            ++ (mkModules { inherit name withSharedModules presets extraModules; });
        specialArgs = {
          inherit flake inputs overlays;
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
    , withSharedModules ? true
    , presets ? [ ]
    , extraModules ? [ ]
    , specialArgs ? { }
    }:
    {
      "${name}" = inputs.nixpkgs.lib.nixosSystem {
        modules = mkModules { inherit name withSharedModules presets extraModules; };
        specialArgs = {
          inherit flake inputs;
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
