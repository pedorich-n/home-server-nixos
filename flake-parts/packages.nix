{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
    };
  };
}
