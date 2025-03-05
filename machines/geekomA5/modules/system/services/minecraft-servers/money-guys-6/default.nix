{ minecraftLib, config, pkgs, lib, ... }:
let
  serverName = "money-guys-6";

  forge = pkgs.callPackage ./_forge.nix { };
  forgeRunner = pkgs.callPackage ./_forge-runner.nix { inherit forge; };
in
{
  config = lib.mkMerge [
    {
      services.minecraft-servers.servers.${serverName} = {
        enable = false;
        autoStart = true;
        openFirewall = true;

        package = forgeRunner;
        serverProperties = {
          allow-flight = true;
          server-port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;
          difficulty = 2;
          level-name = "the_best_1";
          motd = "Money Guys' server. No chickens";
          max-players = 10;
          enable-status = true;
          enforce-secure-profile = false;
          max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
          spawn-protection = 0;
        };
        jvmOpts = minecraftLib.aikarFlagsWith { memory = "5120M"; };

        # symlinks = {
        #   "server-icon.png" = ./icon.png;
        # } // (minecraftLib.mkConsoleAccessSymlink serverName)
        # // (minecraftLib.mkPackwizSymlinks { pkg = inputs.minecraft-modpack.packages.${system}.packwiz-server; folder = "mods"; });

        # files = minecraftLib.mkPackwizSymlinks { pkg = inputs.minecraft-modpack.packages.${system}.packwiz-server; folder = "config"; };
      };
    }
    (lib.mkIf (config.services.minecraft-servers.enable && config.services.minecraft-servers.servers.${serverName}.enable) {
      custom = {
        networking.ports.tcp = {
          "minecraft-${serverName}-game" = { port = 25565; openFirewall = true; };
        };

        # services.minecraft-server-check = {
        #   server-service = "minecraft-server-${serverName}.service";
        # };
      };

      # NOTE Should be the same as labels produced by
      # LINK machines/geekomA5/modules/lib/docker.nix:11
      # services.traefik.dynamicConfigOptions.http = {
      #   routers.metrics-minecraft = {
      #     entryPoints = [ "metrics" ];
      #     rule = "Host(`metrics.${config.custom.networking.domain}`) && Path(`/minecraft`)";
      #     service = "metrics-minecraft";
      #     middlewares = [ "metrics-replacepath-minecraft" ];
      #   };

      #   services.metrics-minecraft = {
      #     loadBalancer.servers = [{ url = "http://localhost:${config.custom.networking.ports.tcp."minecraft-${serverName}-metrics".portStr}"; }];
      #   };

      #   middlewares.metrics-replacepath-minecraft = {
      #     replacePath = {
      #       path = "/metrics";
      #     };
      #   };
      # };
    })
  ];
}
