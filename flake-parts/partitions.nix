{ inputs, config, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
  ];

  partitionedAttrs = {
    devShells = "dev";
    checks = "dev";
    formatter = "dev";
  };

  partitions.dev = {
    extraInputsFlake = ../dev;
    extraInputs = { inherit (config.partitions.dev.extraInputs.nix-dev-flake.inputs) treefmt-nix pre-commit-hooks; };
    module = { inputs, ... }: {
      imports = [
        inputs.nix-dev-flake.flakeModules.default
        ../dev-extra-config.nix
      ];
    };
  };
}
