{ minecraftLib, pkgs, ... }:
let
  serverName = "money-guys-1";
in
{
  networking.firewall = {
    allowedUDPPorts = [
      # 19132 # Geyser
    ];
    allowedTCPPorts = [
      44040 # Metrics Exporter
      44080 # SquareMap
    ];
  };

  services.minecraft-servers.servers = {
    ${serverName} = {
      enable = true;
      autoStart = true;
      openFirewall = true;

      package = pkgs.paperServers.paper-1_20_2;
      serverProperties = {
        server-port = 43000;
        difficulty = 2;
        level-name = "the_best_1";
        motd = "NixOS Managed Server. Humans are not allowed.";
        max-players = 10;
        enable-status = true;
        enforce-secure-profile = false;
        max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
        spawn-protection = 0;
      };
      jvmOpts = minecraftLib.aikarFlagsWith "4096M";

      symlinks = with pkgs; {
        "server-icon.png" = ./server-icon.png;
      } // (minecraftLib.mkConsoleAccessSymlink serverName)
      // (minecraftLib.mkPluginSymlinks {
        AntiPopup = fetchurl {
          # AntiPopup is a plugin aiming to remove chat reporting system entirely using packets.
          url = "https://github.com/KaspianDev/AntiPopup/releases/download/d1fac38/AntiPopup-7.1.jar";
          sha512 = "48f753c07b3b0cc7629f0a8a7f02292f76093e9557f4d7fa527707da8aa506e32a7cada26c2467181e5f7c10dcf598d01969e71a0f73eacda57b63cd93dfe923";
        };
        AureliumSkills = fetchurl {
          # Enhance the survival experience with advanced skills, stats, abilities, and more
          url = "https://hangarcdn.papermc.io/plugins/Archy/AureliumSkills/versions/Beta1.3.23/PAPER/AureliumSkills-Beta1.3.23.jar";
          sha512 = "b78e0daadcdbbdbfdb7b399ecaf26f670917eabf8b192abcd4904c2c27190e31bd9e4fd7af24ffad72828a41dcb66b26ba67c2949ed9074e9403fbfebcf6c28b";
        };
        BKCommonLib = fetchurl {
          # Spigot/Paper Utility Library and Minecraft Server API. Needed for TrainCarts
          url = "https://cdn.modrinth.com/data/rTg6ckWb/versions/jorZqzXs/BKCommonLib-1.20.2-v1-1634.jar";
          sha512 = "f08b582f2874f6c3db76e9c495814382d246bfc8db9c50bd292d59a83f90970b2c8afccba2b7c289c385e31cef086301bad6d728830f019539d54e415fa625f8";
        };
        Chunky = fetchurl {
          # Pre-generates chunks, quickly, efficiently, and safely
          url = "https://hangarcdn.papermc.io/plugins/pop4959/Chunky/versions/1.3.92/PAPER/Chunky-1.3.92.jar";
          sha512 = "63c41849020276a6f0156fc5d11abef77ca53c1ab44a242c97ca522666809c29427805cff38b2de484c7d5e2f3e7eb3eb8a989abcfebbd20419718881e12b00b";
        };
        DamageIndicator = fetchurl {
          # Indicators for damage dealt to entities!
          url = "https://github.com/MagicCheese1/Damage-Indicator/releases/download/v1.3.8/DamageIndicator.jar";
          sha512 = "2390ec8bf453c9eca7dd0dbd654f0af7b905e8499a7a81d2acac8490c2e1842e476a4c1ca453df188e98cebb4c8cfe23924a02fea00f52cfa7d0f26f6ce05538";
        };
        DeathChest = fetchurl {
          # A spigot plugin for spawning a chest when the player dies. 
          url = "https://github.com/DevCyntrix/death-chest/releases/download/v2.1.1/deathchest.jar";
          sha512 = "648fec5ae83437cf51d2732f513039c031e6bae34ead58c4b1def4b9f372445f885ba771679e5f28d6171ca6b812ce681a6347e997d2bbfca9a3f0602bfb04ab";
        };
        DirectionHUD = fetchurl {
          # On screen HUD plugin that has many customizable features. Save coordinates, see death locations, track players, all at a glance!
          url = "https://cdn.modrinth.com/data/41anAf7M/versions/q0GJRvlm/directionhud-spigot-1.1.4%2B1.18-1.20.2.jar";
          sha512 = "deceb91cdb3cae71286667a52fe00e1ef2bf8bc812ca5374b832b684a1d5b43b47f0d17c1793f6a5a0ba6a579215fd5ca11ffb2a8b97959a0dce8f75d7894d40";
        };
        DiscordIntegration = fetchurl {
          # This mod links your server chat with a channel on your discord server
          url = "https://cdn.modrinth.com/data/rbJ7eS5V/versions/8aXeAavL/dcintegration-spigot-3.0.3-1.20.2.jar";
          sha512 = "ad5e34f1d9ee3bfb37b2adc66c3fcbb4845deb43bdea2f598a24f26786c85dc39a3ac8d0308b0c738b07326ca94392e0a310905603fb00895f67aadccfcec683";
        };
        FarmingUpgrade = fetchurl {
          # Bukkit plugin improving farming mechanics.
          url = "https://github.com/hypmc/FarmingUpgrade/releases/download/v1.6.0/farmingupgrade-1.6.0.jar";
          sha512 = "b87f2044ffd529a9f7d8e0c659c9dce48c242dded4f7a51e10bd6de06ae78d7f975888ea45ae95131de0f0dee2695b33c1e63b96532071b40cca12452ea3fe02";
        };
        FloodGate = fetchurl {
          # Hybrid mode plugin to allow for connections from Geyser to join online mode servers.
          url = "https://ci.opencollab.dev/job/GeyserMC/job/Floodgate/job/master/95/artifact/spigot/build/libs/floodgate-spigot.jar";
          sha512 = "7a1057d430ea405c71a6925525783390aa358188de720c78e4e2160aa198bb4c9654eb2eec7d325b6e3b2cc768c5695ef3e30d664c14c63359d75e67bf3ff149";
        };
        Geyser = fetchurl {
          # A bridge/proxy allowing you to connect to Minecraft: Java Edition servers with Minecraft: Bedrock Edition.
          url = "https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/1522/artifact/bootstrap/spigot/build/libs/Geyser-Spigot.jar";
          sha512 = "8f79b72cab3ffaf8e781bdb6012d936d922d5077f14848074df6b5c66e93df222df69b80282e280cfe4e99f8cebe14777066444fbc196c2b5740dbfcc7d7105b";
        };
        SlimeFun = fetchurl {
          # Turn the server into a modpack without ever installing a single mod. It offers everything you could possibly imagine. From Backpacks to Jetpacks!
          url = "https://thebusybiscuit.github.io/builds/TheBusyBiscuit/Slimefun4/master/Slimefun4-1104.jar";
          sha512 = "63b3ec6a9e20a39fffdf646d24aa77354e44f479d16946be4da6190656804703369b586978fe56b55851bbaa46cf16f8531fa4e5307408adbf16439bfbafe1ae";
        };
        SquareMap = fetchurl {
          # A minimalistic & lightweight world map viewer for Minecraft servers, using the vanilla map rendering style
          url = "https://cdn.modrinth.com/data/PFb7ZqK6/versions/mPe19wqu/squaremap-paper-mc1.20.2-1.2.1.jar";
          sha512 = "a48048d7e300fbc30ce36148be835ae1ebda29828a945683e62fa5c13fd77d000942e40d6e70d5e527ab51b8e57a20f41e818c092f00e40a8fa8f97619db2dba";
        };
        TrainCarts = fetchurl {
          # Automated metro networks, rollercoasters, gondolas, ski-lifts or amusement park rides. 
          url = "https://cdn.modrinth.com/data/7xgugLBo/versions/X7sHFeSR/TrainCarts-1.20.2-v1-1464.jar";
          sha512 = "fbc003d0917ae1babc8244317f0e32065fbe70d0ad4c6631b450578fbce1038ba97742a67705f730c5ec819ca6add9485694b5c91b7654970eec877079c71036";
        };
        UnifiedMetrics = fetchurl {
          # Fully-featured metrics collection agent for Minecraft servers
          url = "https://github.com/Cubxity/UnifiedMetrics/releases/download/v0.3.x-SNAPSHOT/unifiedmetrics-platform-bukkit-0.3.9-SNAPSHOT.jar";
          sha512 = "2c43c7d3faa28fb5057c632a590f9db6fda8f6a7535804d4243225e760e8536522b62a01d119ac9c31a78729e67570ea73dab953950e0aecab7911fa57b98aba";
        };
        WhatIsThis = fetchurl {
          # Plugin that uses the action bar to display the name of the block or entity currently being looked at.
          url = "https://github.com/steve4744/WhatIsThis/releases/download/v5.4-SNAPSHOT.51/WhatIsThis-5.4-SNAPSHOT.jar";
          sha512 = "39b1841108ed4b7ad88d86eecb42fbc179f4a4756f0dd096e1685e0a5269fc71212489211b60ad931a37644d5097fbb38ca365da76f87094af27e5b006ea7ea1";
        };
      });
    };
  };
}
