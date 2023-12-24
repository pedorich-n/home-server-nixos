{ pkgs, ... }: {
  _module.args.minecraftLib = pkgs.callPackage ./lib.nix { };

  imports = [
    ./server-check.nix
    ./playit.nix
    ./money-guys-1
    ./money-guys-2
    ./money-guys-3
    ./money-guys-4
  ];

  services = {
    minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/store/minecraft";
    };

    minecraft-server-check = {
      enable = false;
      server-service = "minecraft-server-money-guys-4.service";
      tunnel-service = "playit.service";
      restart-timeout = 90;
    };
  };
}
