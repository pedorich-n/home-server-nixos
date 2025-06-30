{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
      update-nvfetcher = pkgs.callPackage ../pkgs/update-nvfetcher { };

      modpack = pkgs.callPackage ../pkgs/minecraft-modpacks/crying-obsidian.nix { };
    };
  };
}
