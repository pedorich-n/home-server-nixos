{ flake, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      devShells = {
        tf = pkgs.callPackage ../shells/tf.nix { nixosConfig = flake.nixosConfigurations.geekomA5; };
      };
    };
}
