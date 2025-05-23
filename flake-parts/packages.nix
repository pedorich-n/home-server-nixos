{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
      modpack = pkgs.callPackage ../pkgs/minecraft-modpacks/crying-obsidian.nix { };

      cockpit-plugins-update = pkgs.callPackage ../pkgs/cockpit-plugins/updater.nix { };
    };
  };
}
