{ pkgs, ... }: {
  _module.args.minecraftLib = pkgs.callPackage ./lib.nix { };

  imports = [
    ./server-check.nix
    ./playit.nix
    ./money-guys-1
    ./money-guys-2
  ];

  services = {
    minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
    };

    minecraft-server-check = {
      enable = true;
      server-service = "minecraft-server-money-guys-2.service";
      tunnel-service = "playit.service";
    };
  };
}
