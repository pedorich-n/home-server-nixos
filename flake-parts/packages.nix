{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        update-nvfetcher = pkgs.callPackage ../pkgs/update-nvfetcher { };

        modpack = pkgs.callPackage ../pkgs/minecraft-modpacks/crying-obsidian.nix { };
        modpack2 = pkgs.callPackage ../pkgs/minecraft-modpacks/monkegeddoon.nix { };
      };
    };
}
