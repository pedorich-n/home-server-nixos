{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-netdata.url = "github:rhoriguchi/nixpkgs/netdata";

    systems.url = "github:nix-systems/default-linux";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager-config = {
      url = "github:pedorich-n/home-manager-config";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nixpkgs-cassandra.follows = "";
        nix-vscode-extensions.follows = "";
        rust-overlay.follows = "";
      };
    };

    auto-cpufreq = {
      #url = "github:AdnanHodzic/auto-cpufreq"; # TODO: uncomment this once requests library is updated in nixpkgs
      url = "github:AdnanHodzic/auto-cpufreq/becd5b89963fa54fef3566147f3fd2087f8a5842";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
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

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
      # url = "github:pedorich-n/quadlet-nix/fix-container-notify";
      # url = "git+file:///home/pedorich_n/Projects/quadlet-nix";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    home-server-nixos-secrets = {
      url = "git+ssh://git@github.com/pedorich-n/home-server-nixos-secrets";
      # url = "git+file:///home/pedorich_n/Projects/home-server-nixos-secrets";
      flake = false;
    };

    airtable-telegram-bot = {
      url = "git+ssh://git@github.com/pedorich-n/airtable-telegram-lessons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
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

    playit-nixos-module = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
      };
    };

    homeassistant-docker-venv = {
      url = "github:tribut/homeassistant-docker-venv";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, systems, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
    systems = import systems;

    debug = true;

    imports = lib.filesystem.listFilesRecursive ./flake-parts;
  });
}
