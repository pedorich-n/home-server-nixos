{ flake, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        version-updater = pkgs.callPackage ../shells/version-updater.nix { };

        tf = pkgs.callPackage ../shells/tf.nix { nixosConfig = flake.nixosConfigurations.geekomA5; };
      };
    };
}
