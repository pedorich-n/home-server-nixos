{ minecraftLib, pkgs, ... }:
{
  networking.firewall = {
    allowedUDPPorts = [
      # 19132 # Geyser
    ];
    allowedTCPPorts = [
      44080 # SquareMap
    ];
  };

  services.minecraft-servers.servers = {
    "money-guys-1" = {
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
      };
      jvmOpts = minecraftLib.aikarFlagsWith "5120M";

      symlinks = with pkgs; {
        "server-icon.png" = ./server-icon.png;
        "plugins/AureliumSkills.jar" = fetchurl {
          # Enhance the survival experience with advanced skills, stats, abilities, and more
          url = "https://hangarcdn.papermc.io/plugins/Archy/AureliumSkills/versions/Beta1.3.23/PAPER/AureliumSkills-Beta1.3.23.jar";
          sha512 = "b78e0daadcdbbdbfdb7b399ecaf26f670917eabf8b192abcd4904c2c27190e31bd9e4fd7af24ffad72828a41dcb66b26ba67c2949ed9074e9403fbfebcf6c28b";
        };
        "plugins/Chunky.jar" = fetchurl {
          # Pre-generates chunks, quickly, efficiently, and safely
          url = "https://hangarcdn.papermc.io/plugins/pop4959/Chunky/versions/1.3.92/PAPER/Chunky-1.3.92.jar";
          sha512 = "63c41849020276a6f0156fc5d11abef77ca53c1ab44a242c97ca522666809c29427805cff38b2de484c7d5e2f3e7eb3eb8a989abcfebbd20419718881e12b00b";
        };
        "plugins/DamageIndicator.jar" = fetchurl {
          # Indicators for damage dealt to entities!
          url = "https://github.com/MagicCheese1/Damage-Indicator/releases/download/v1.3.8/DamageIndicator.jar";
          sha512 = "2390ec8bf453c9eca7dd0dbd654f0af7b905e8499a7a81d2acac8490c2e1842e476a4c1ca453df188e98cebb4c8cfe23924a02fea00f52cfa7d0f26f6ce05538";
        };
        "plugins/DeathChest.jar" = fetchurl {
          # A spigot plugin for spawning a chest when the player dies. 
          url = "https://github.com/DevCyntrix/death-chest/releases/download/v2.1.1/deathchest.jar";
          sha512 = "648fec5ae83437cf51d2732f513039c031e6bae34ead58c4b1def4b9f372445f885ba771679e5f28d6171ca6b812ce681a6347e997d2bbfca9a3f0602bfb04ab";
        };
        "plugins/DirectionHUD.jar" = fetchurl {
          # On screen HUD plugin that has many customizable features. Save coordinates, see death locations, track players, all at a glance!
          url = "https://cdn.modrinth.com/data/41anAf7M/versions/q0GJRvlm/directionhud-spigot-1.1.4%2B1.18-1.20.2.jar";
          sha512 = "deceb91cdb3cae71286667a52fe00e1ef2bf8bc812ca5374b832b684a1d5b43b47f0d17c1793f6a5a0ba6a579215fd5ca11ffb2a8b97959a0dce8f75d7894d40";
        };
        "plugins/DiscordIntegration.jar" = fetchurl {
          # This mod links your server chat with a channel on your discord server
          url = "https://cdn.modrinth.com/data/rbJ7eS5V/versions/8aXeAavL/dcintegration-spigot-3.0.3-1.20.2.jar";
          sha512 = "ad5e34f1d9ee3bfb37b2adc66c3fcbb4845deb43bdea2f598a24f26786c85dc39a3ac8d0308b0c738b07326ca94392e0a310905603fb00895f67aadccfcec683";
        };
        "plugins/FloodGate.jar" = fetchurl {
          # Hybrid mode plugin to allow for connections from Geyser to join online mode servers.
          url = "https://ci.opencollab.dev/job/GeyserMC/job/Floodgate/job/master/95/artifact/spigot/build/libs/floodgate-spigot.jar";
          sha512 = "7a1057d430ea405c71a6925525783390aa358188de720c78e4e2160aa198bb4c9654eb2eec7d325b6e3b2cc768c5695ef3e30d664c14c63359d75e67bf3ff149";
        };
        "plugins/Geyser.jar" = fetchurl {
          # A bridge/proxy allowing you to connect to Minecraft: Java Edition servers with Minecraft: Bedrock Edition.
          url = "https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/1522/artifact/bootstrap/spigot/build/libs/Geyser-Spigot.jar";
          sha512 = "8f79b72cab3ffaf8e781bdb6012d936d922d5077f14848074df6b5c66e93df222df69b80282e280cfe4e99f8cebe14777066444fbc196c2b5740dbfcc7d7105b";
        };
        "plugins/SquareMap.jar" = fetchurl {
          # A minimalistic & lightweight world map viewer for Minecraft servers, using the vanilla map rendering style
          url = "https://cdn.modrinth.com/data/PFb7ZqK6/versions/mPe19wqu/squaremap-paper-mc1.20.2-1.2.1.jar";
          sha512 = "a48048d7e300fbc30ce36148be835ae1ebda29828a945683e62fa5c13fd77d000942e40d6e70d5e527ab51b8e57a20f41e818c092f00e40a8fa8f97619db2dba";
        };
      };

    };
  };
}
