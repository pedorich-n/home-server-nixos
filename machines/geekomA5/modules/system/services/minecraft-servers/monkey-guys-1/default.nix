{ inputs, config, pkgs, lib, ... }:
let
  minecraftLib = inputs.nix-minecraft.lib;
  serverName = "monkey-guys-1";

  modpack = pkgs.minecraft-modpacks.crying-obsidian;

  # https://docs.papermc.io/paper/aikars-flags
  aikarFlagsWith = { memory }: builtins.concatStringsSep " " [
    "-Xms${memory}"
    "-Xmx${memory}"
    "-XX:+UseG1GC"
    "-XX:+ParallelRefProcEnabled"
    "-XX:MaxGCPauseMillis=200"
    "-XX:+UnlockExperimentalVMOptions"
    "-XX:+DisableExplicitGC"
    "-XX:+AlwaysPreTouch"
    "-XX:G1NewSizePercent=30"
    "-XX:G1MaxNewSizePercent=40"
    "-XX:G1HeapRegionSize=8M"
    "-XX:G1ReservePercent=20"
    "-XX:G1HeapWastePercent=5"
    "-XX:G1MixedGCCountTarget=4"
    "-XX:InitiatingHeapOccupancyPercent=15"
    "-XX:G1MixedGCLiveThresholdPercent=90"
    "-XX:G1RSetUpdatingPauseTimePercent=5"
    "-XX:SurvivorRatio=32"
    "-XX:+PerfDisableSharedMem"
    "-XX:MaxTenuringThreshold=1"
  ];
in
{
  config = lib.mkMerge [
    {
      services.minecraft-servers.servers.${serverName} = {
        enable = true;
        autoStart = true;
        openFirewall = true;

        package = pkgs.fabricServers.fabric-1_20_1;
        serverProperties = {
          allow-flight = true;
          server-port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;
          difficulty = 2;
          level-name = "the_best_1";
          motd = ''🐒Leave society, be a monkey🐒'';
          max-players = 10;
          enable-status = true;
          enforce-secure-profile = false;
          max-world-size = 20000; # Value is a radius, so the world size is 40000x40000
          spawn-protection = 0;
        };
        jvmOpts = aikarFlagsWith { memory = "6144M"; };

        symlinks = {
          "server-icon.png" = "${modpack}/server-icon.png";
        } // minecraftLib.collectFilesAt modpack "mods";

        files =
          (minecraftLib.collectFilesAt modpack "config") //
          (minecraftLib.collectFilesAt modpack "datapacks");
      };
    }
    (lib.mkIf (config.services.minecraft-servers.enable && config.services.minecraft-servers.servers.${serverName}.enable) {
      # NOTE Should be the same as labels produced by
      # LINK machines/geekomA5/modules/lib/container.nix:11
      services.traefik.dynamicConfigOptions.http = {
        routers.metrics-minecraft = {
          entryPoints = [ "metrics" ];
          rule = "Host(`metrics.${config.custom.networking.domain}`) && Path(`/minecraft`)";
          service = "metrics-minecraft";
          middlewares = [ "metrics-replacepath-minecraft" ];
        };

        services.metrics-minecraft = {
          loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.minecraft-money-guys-6-metrics.portStr}"; }];
        };

        middlewares.metrics-replacepath-minecraft = {
          replacePath = {
            path = "/metrics";
          };
        };
      };

      custom = {
        networking.ports.tcp = {
          "minecraft-${serverName}-game" = { port = 25565; openFirewall = true; };
          "minecraft-${serverName}-metrics" = { port = 25585; openFirewall = false; };
        };

        minecraft-servers.check.servers = {
          ${serverName} = {
            address = "127.0.0.1";
            port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;

            notify = {
              # socket = notifySocket;
              # pidPath = pidFile;
            };

            healthCheck = {
              retries = 15;
              intervalSeconds = 5;
            };
          };
        };
      };
    })
  ];
}
