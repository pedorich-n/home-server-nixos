{
  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-netdata.url = "github:rhoriguchi/nixpkgs/netdata";

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
      url = "git+ssh://git@github.com/pedorich-n/home-manager-config";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nix-vscode-extensions.follows = "";
        rust-overlay.follows = "";
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

    copyparty = {
      url = "github:9001/copyparty";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };

    homeassistant-docker-venv = {
      url = "github:tribut/homeassistant-docker-venv";
      flake = false;
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    airtable-telegram-bot = {
      url = "git+ssh://git@github.com/pedorich-n/airtable-telegram-lessons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        flake-utils.follows = "flake-utils";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        pyproject-build-systems.follows = "pyproject-build-systems";
      };
    };

    geekdo-sync = {
      url = "git+ssh://git@github.com/pedorich-n/geekdo-sync";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        pyproject-build-systems.follows = "pyproject-build-systems";
      };
    };

  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = import systems;

        debug = true;

        imports = lib.filesystem.listFilesRecursive ./flake-parts;
      }
    );
}
