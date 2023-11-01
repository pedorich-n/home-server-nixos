{ pkgs, ... }: {
  _module.args.minecraftLib = pkgs.callPackage ./lib.nix { };

  imports = [
    ./money-guys-1
  ];

  services.minecraft-servers = {
    enable = true;
    openFirewall = true;
    eula = true;
    dataDir = "/mnt/store/minecraft";
  };
}
