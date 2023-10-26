{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.minecraft-servers;
in
{
  ###### interface
  options = {
    custom.minecraft-servers = {
      enable = mkEnableOption "Minecraft Servers";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    networking.firewall = {
      allowedUDPPorts = [ 19132 ]; # For Geyser
    };

    services.minecraft-servers = {
      enable = true;
      openFirewall = true;
      eula = true;
      dataDir = "/mnt/ha-store/minecraft";

      servers = {
        "money-guys-1" = {
          enable = true;
          autoStart = true;
          openFirewall = true;

          package = pkgs.fabricServers.fabric-1_20_2;
          serverProperties = {
            server-port = 43000;
            difficulty = 2;
            enable-status = true;
            level-name = "the_best_1";
            motd = "NixOS Managed Server. Humans are not allowed.";
            max-players = 10;
          };
          jvmOpts = "-Xms1024M -Xmx4092M";

          symlinks = with pkgs; {
            mods = linkFarmFromDrvs "mods" (builtins.attrValues {
              FabricApi = fetchurl {
                # Lightweight and modular API providing common hooks and intercompatibility measures utilized by mods using the Fabric toolchain.
                url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/ZI1BEw1i/fabric-api-0.90.4%2B1.20.2.jar";
                sha512 = "31f3b114c2b37bae5419e162d212bc7aaffcad9df122e94d2a461e9f92d694af6ab5b7a2d9684f6df75dd7df5c7b0d2ce8df2046fd6bccd8dd4fa0fa3a3727de";
              };
              FerriteCore = fetchurl {
                # Memory usage optimizations
                url = "https://cdn.modrinth.com/data/uXXizFIs/versions/unerR5MN/ferritecore-6.0.1-fabric.jar";
                sha512 = "9b7dc686bfa7937815d88c7bbc6908857cd6646b05e7a96ddbdcada328a385bd4ba056532cd1d7df9d2d7f4265fd48bd49ff683f217f6d4e817177b87f6bc457";
              };
              Floodgate = fetchurl {
                # Hybrid mode plugin to allow for connections from Geyser to join online mode servers.
                url = "https://cdn.modrinth.com/data/bWrNNfkb/versions/y7veyylg/floodgate-fabric.jar";
                sha512 = "c3b5d92eca7c9621d70ab745445d890ee74634c3dbe208e6447f08c5feae72f33c9b5c3d8e01ea27c1bb4048e9102a1a65945d2ba98feecfb43d49e79cbd6254";
              };
              Geyser = fetchurl {
                # A bridge/proxy allowing you to connect to Minecraft: Java Edition servers with Minecraft: Bedrock Edition.
                url = "https://cdn.modrinth.com/data/wKkoqHrH/versions/CNONDqIv/geyser-fabric-2.2.0-SNAPSHOT%2Bbuild.339.jar";
                sha512 = "abd16cd0ec91d82da0f739933fe23b34eda54d6ff8f1a80eb93d16ac670559e31621dce9c16b7578f11b570198873fa43dc82b5fd2386e4afd027666614d5ce9";
              };
              Krypton = fetchurl {
                # A mod to optimize the Minecraft networking stack
                url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/cQ60Ouax/krypton-0.2.4.jar";
                sha512 = "37a076ea08f7f49aebc8b0a1519ae7d1844bf169134b152f446dc7b95d37567808b96e8523001b98ebd19950420eb76da35df47e8d9b9af0846e68c7c829d7c0";
              };
              LazyDFU = fetchurl {
                # Makes the game boot faster by deferring non-essential initialization
                url = "https://cdn.modrinth.com/data/hvFnDODi/versions/0.1.3/lazydfu-0.1.3.jar";
                sha512 = "dc3766352c645f6da92b13000dffa80584ee58093c925c2154eb3c125a2b2f9a3af298202e2658b039c6ee41e81ca9a2e9d4b942561f7085239dd4421e0cce0a";
              };
              Lithium = fetchurl {
                # No-compromises game logic/server optimization mod
                url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/qdzL5Hkg/lithium-fabric-mc1.20.2-0.12.0.jar";
                sha512 = "88df5f96ee5a3011dbb2aae011b5c85166f9942906e4ebc58ebb7b452f01e18020b970aad3facebd02eb67ac4beea03de333414cf66172d817fa5cae50e1c73d";
              };
              ModernFix = fetchurl {
                # All-in-one mod that improves performance, reduces memory usage, and fixes many bugs.
                url = "https://cdn.modrinth.com/data/nmDcB62a/versions/5YONh7M3/modernfix-fabric-5.8.1%2Bmc1.20.2.jar";
                sha512 = "4ff35db3f997cbe54580db4bf73df92095496dae817952d9cba7ad7c03a5894b3d63248ff1dbd77135c97bcb4de2a03cfc98e23e6baf1d766d13f8a1c7300f9c";
              };
              Starlight = fetchurl {
                # Rewrites the light engine to fix lighting performance and lighting errors
                url = "https://cdn.modrinth.com/data/H8CaAYZC/versions/PLbxwptm/starlight-1.1.3%2Bfabric.5867eae.jar";
                sha512 = "bb9426b5218550d8f9baa3022604feec9f72ac1f1efea07ee70d9871040628d1db039b8c78f30593ab7a5dd4706317a141a4681b6c3adab3bfe7d862003e89e7";
              };
            });
          };
        };
      };
    };
  };
}
