{
  perSystem = { pkgs, ... }: {
    packages = {
      update-containers = pkgs.callPackage ../pkgs/nvchecker/containers/updater.nix { };
      update-terraform-providers = pkgs.callPackage ../pkgs/nvchecker/terraform-providers/updater.nix { };
    };
  };
}
