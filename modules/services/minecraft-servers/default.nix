{
  imports = [
    ./money-guys-1.nix
  ];

  services.minecraft-servers = {
    enable = true;
    openFirewall = true;
    eula = true;
    dataDir = "/mnt/store/minecraft";
  };
}
