{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    airtable-telegram-bot = {
      url = "git+ssh://git@github.com/pedorich-n/airtable-telegram-lessons";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };
  outputs = { self, nixpkgs, arion, ragenix, airtable-telegram-bot, ... } @ inputs: {
    nixosConfigurations = {
      nucbox5 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          arion.nixosModules.arion
          ragenix.nixosModules.default
          airtable-telegram-bot.nixosModules.default
          ./configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };
    packages.x86_64-linux.nucbox5 = self.nixosConfigurations.nucbox5.config.system.build.vm;
  };
}
