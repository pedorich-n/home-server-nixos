{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts"; # Only here to have single entry in the flake.lock

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
      };
    };

    nixos-mutable-files-manager = {
      url = "git+ssh://git@github.com/pedorich-n/nixos-mutable-files-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

  };
  outputs = { self, nixpkgs, arion, ragenix, airtable-telegram-bot, nixos-mutable-files-manager, ... } @ inputs: {
    nixosConfigurations = {
      nucbox5 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          arion.nixosModules.arion
          ragenix.nixosModules.default
          airtable-telegram-bot.nixosModules.default
          nixos-mutable-files-manager.nixosModules.default
          ./configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };
    packages.x86_64-linux.nucbox5 = self.nixosConfigurations.nucbox5.config.system.build.vm;
  };
}
