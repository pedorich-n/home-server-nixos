{
  nixConfig = {
    extra-substituters = [ "https://playit-nixos-module.cachix.org" ];
    extra-trusted-public-keys = [ "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";


    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    haumea = {
      url = "github:nix-community/haumea";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
        treefmt-nix.follows = "";
        nix-github-actions.follows = "";
      };
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        darwin.follows = "";
        home-manager.follows = "";
      };
    };

    home-server-nixos-secrets = {
      url = "git+ssh://git@github.com/pedorich-n/home-server-nixos-secrets?ref=machine-specific";
      flake = false;
    };

    airtable-telegram-bot = {
      url = "git+ssh://git@github.com/pedorich-n/airtable-telegram-lessons";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        flake-utils.follows = "flake-utils";
        poetry2nix.follows = "poetry2nix";
      };
    };

    nixos-mutable-files-manager = {
      url = "github:pedorich-n/nixos-mutable-files-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        flake-utils.follows = "flake-utils";
        poetry2nix.follows = "poetry2nix";
      };
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };

    fabric-modpack = {
      url = "github:pedorich-n/FabricModpack";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
      };
    };

    playit-nixos-module = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
        crane.follows = "crane";
      };
    };

    homer-theme = {
      url = "github:walkxcode/homer-theme";
      flake = false;
    };

  };

  outputs = inputs@{ flake-parts, systems, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, flake-parts-lib, ... }: {
    systems = import systems;

    imports = import ./flake-parts {
      inherit (flake-parts-lib) importApply;
      inherit withSystem inputs;
      flake = self;
    };
  });
}
