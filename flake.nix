{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";


    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
        # agenix.inputs.darwin.follows = ""; # https://github.com/NixOS/nix/issues/5790
      };
    };

    home-server-nixos-secrets = {
      url = "git+ssh://git@github.com/pedorich-n/home-server-nixos-secrets";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

    airtable-telegram-bot = {
      url = "git+ssh://git@github.com/pedorich-n/airtable-telegram-lessons";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        flake-utils.follows = "flake-utils";
      };
    };

    nixos-mutable-files-manager = {
      url = "github:pedorich-n/nixos-mutable-files-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    # perSystem = { config, lib, pkgs, inputs', ... }: {
    #   packages = {
    #     nucbox5 = flake.nixosConfigurations.nucbox5.config.system.build.vm;
    #   };
    # };

    flake = {
      nixosConfigurations = {
        nucbox5 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.arion.nixosModules.arion
            inputs.ragenix.nixosModules.default
            inputs.airtable-telegram-bot.nixosModules.default
            inputs.nixos-mutable-files-manager.nixosModules.default
            ./configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
  };
}
