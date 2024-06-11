{ minecraftLib, lib, config, pkgs, inputs, system, ... }:
let
  serverName = "money-guys-5";

  forge = pkgs.callPackage ./_forge.nix { };
  forgeRunnable = pkgs.callPackage ./_forge-runnable.nix { inherit forge; };
in
{
  custom.networking.ports.tcp = lib.mkIf config.services.minecraft-servers.servers.${serverName}.enable {
    "minecraft-${serverName}-game" = { port = 43000; openFirewall = true; };
    "minecraft-${serverName}-metrics" = { port = 44040; openFirewall = true; };
  };

  services = {
    minecraft-servers.servers = {
      ${serverName} = {
        enable = true;
        autoStart = true;
        openFirewall = true;

        package = forgeRunnable;
        serverProperties = {
          server-port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;
          difficulty = 2;
          level-name = "the_best_1";
          motd = "NixOS Managed Server. Humans are not allowed.";
          max-players = 10;
          enable-status = true;
          enforce-secure-profile = false;
          max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
          spawn-protection = 0;
        };
        jvmOpts = minecraftLib.aikarFlagsWith { memory = "5120M"; };

        symlinks = {
          "server-icon.png" = ./icon.png;
        } // (minecraftLib.mkConsoleAccessSymlink serverName)
        // (minecraftLib.mkPackwizSymlinks { pkg = inputs.fabric-modpack.packages.${system}.packwiz-server; folder = "mods"; });

        files = minecraftLib.mkPackwizSymlinks { pkg = inputs.fabric-modpack.packages.${system}.packwiz-server; folder = "config"; };
      };
    };

    # NOTE Should be the same as labels produced by
    # LINK machines/geekomA5/modules/lib/docker.nix:11
    # traefik.dynamicConfigOptions.http = lib.mkIf config.services.minecraft-servers.servers.${serverName}.enable {
    #   routers.metrics-minecraft = {
    #     entryPoints = [ "metrics" ];
    #     rule = "Host(`metrics.${config.custom.networking.domain}`) && Path(`/minecraft`)";
    #     service = "metrics-minecraft";
    #     middlewares = [ "metrics-replacepath-minecraft" ];
    #   };

    #   services.metrics-minecraft = {
    #     loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp.minecraft-money-guys-4-metrics.portStr}"; }];
    #   };

    #   middlewares.metrics-replacepath-minecraft = {
    #     replacePath = {
    #       path = "/metrics";
    #     };
    #   };
    # };
  };
}
