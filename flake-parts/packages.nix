{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
      mc-monitor = pkgs.callPackage ../pkgs/mc-monitor { };
      modpack = pkgs.callPackage ../pkgs/minecraft-modpacks/crying-obsidian.nix { };

      cockpit-plugins-update = pkgs.callPackage ../pkgs/cockpit-plugins/updater.nix { };
    };
  };
}
