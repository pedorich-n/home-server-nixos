{ flake, inputs, withSystem, flake-parts-lib, config, lib, ... }:
let
  nixosConfigurationSubmodule = lib.types.submodule {
    options = {
      withSharedModules = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      withPresets = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.deferredModule);
        default = _: [ ];
      };

      extraModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [ ];
      };

      enableDeploy = lib.mkEnableOption "deploy" // { default = true; };

      deploySettings = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
      };
    };
  };


  nixosCommonModules = flake.lib.loaders.listFilesRecursively { src = "${flake}/shared-modules/nixos/common"; };

  nixosPresetModules =
    let
      root = "${flake}/shared-modules/nixos/presets";
      availablePresets = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir root));
      mkPresetModule = preset: {
        ${preset} = {
          _file = "${./builders.nix}#nixosPresetModules.${lib.escapeNixIdentifier preset}"; # Helps with debugging
          imports = flake.lib.loaders.listFilesRecursively { src = "${root}/${preset}"; };
        };
      };
    in
    lib.foldl' (acc: preset: acc // (mkPresetModule preset)) { } availablePresets;

  loadMachine = name: flake.lib.loaders.listFilesRecursively { src = "${flake}/machines/${name}"; };

  overlays = import "${flake}/overlays/custom-packages.nix";

  mkSystem = name: cfg: inputs.nixpkgs.lib.nixosSystem {
    modules =
      [{
        _module.args = {
          inherit flake overlays;
        };

        networking.hostName = lib.mkDefault name;
      }]
      ++ (loadMachine name)
      ++ lib.optionals cfg.withSharedModules nixosCommonModules
      ++ (cfg.withPresets nixosPresetModules)
      ++ cfg.extraModules;

    specialArgs = {
      inherit inputs; # If passed in _module.args leads to infinite recursion :(
    };
  };

  mkDeployNode = name: cfg:
    let
      nixosCfg = config.flake.nixosConfigurations.${name};
    in
    withSystem nixosCfg.pkgs.system ({ deployPkgs, ... }: {
      hostname = name;
      interactiveSudo = false;
      magicRollback = true;
      remoteBuild = true;

      profiles = {
        system = {
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos nixosCfg;
        } // cfg.deploySettings;
      };
    });
in
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    builders = {
      nixosConfigurations = lib.mkOption {
        type = lib.types.attrsOf nixosConfigurationSubmodule;
        default = { };
      };
    };
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs mkSystem flake.builders.nixosConfigurations;

    deploy.nodes = lib.mapAttrs mkDeployNode (lib.filterAttrs (_: cfg: cfg.enableDeploy) config.flake.builders.nixosConfigurations);
  };
}
