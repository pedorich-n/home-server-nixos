{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
      mc-monitor = pkgs.callPackage ../pkgs/mc-monitor { };
      modpack = pkgs.callPackage ../pkgs/minecraft-modpack { };

      cockpit-files = pkgs.callPackage ../pkgs/cockpit/files.nix { };
      cockpit-podman = pkgs.callPackage ../pkgs/cockpit/podman.nix { };
    };
  };
}
