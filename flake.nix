{
  nixConfig = {
    extra-substituters = [ "https://playit-nixos-module.cachix.org" ];
    extra-trusted-public-keys = [ "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs-netdata.url = "github:rhoriguchi/nixpkgs/netdata-newer?shallow=true";
    nixpkgs-netdata.url = "github:pedorich-n/nixpkgs/netdata-ndsudo?shallow=true";
    # nixpkgs-netdata.url = "git+file:///home/pedorich_n/Projects/nixpkgs?shallow=true";

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

    personal-home-manager = {
      url = "git+ssh://git@github.com/pedorich-n/config.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-nix.follows = "";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        home-manager-diff.follows = "";
        nix-vscode-extensions.follows = "";
        rust-overlay.follows = "";
      };
    };

    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
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

    terranix = {
      # url = "github:terranix/terranix";
      url = "github:pedorich-n/terranix/local-merged";
      # url = "git+file:///home/pedorich_n/Projects/terranix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        terranix-examples.follows = "";
        bats-assert.follows = "";
        bats-support.follows = "";
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
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
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
      # url = "git+ssh://git@github.com/pedorich-n/home-server-nixos-secrets";
      url = "git+file:///home/pedorich_n/Projects/home-server-nixos-secrets";
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

    jinja2-renderer = {
      url = "github:pedorich-n/jinja2-renderer";
      # url = "git+file:///home/pedorich_n/Projects/jinja2-renderer";
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

    minecraft-modpack = {
      url = "github:pedorich-n/MinecraftModpack";
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
      };
    };

    trash-guides = {
      url = "github:TRaSH-Guides/Guides";
      flake = false;
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
