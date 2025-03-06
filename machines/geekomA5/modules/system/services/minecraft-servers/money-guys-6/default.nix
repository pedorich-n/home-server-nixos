{ minecraftLib, config, pkgs, lib, ... }:
let
  serverName = "money-guys-6";

  forge = pkgs.callPackage ./_forge.nix { };
  forgeRunner = pkgs.callPackage ./_forge-runner.nix { inherit forge; };

  modpack = pkgs.minecraft-modpack;
  server-icon = pkgs.runCommand "server-icon.png"
    {
      nativeBuildInputs = [ pkgs.imagemagick ];
    } ''
    convert "${modpack}/icon.jpg" -resize 64x64 $out
  '';

  pidFile = "/run/minecraft/${serverName}.pid";
in
{
  config = lib.mkMerge [
    {
      services.minecraft-servers.servers.${serverName} = {
        enable = true;
        autoStart = true;
        openFirewall = true;

        package = forgeRunner;
        serverProperties = {
          allow-flight = true;
          server-port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;
          difficulty = 2;
          level-name = "the_best_1";
          motd = ''\u00A72Money Guys\u00A7r - you better settle your bill in time'';
          max-players = 10;
          enable-status = true;
          enforce-secure-profile = false;
          max-world-size = 8000; # Value is a radius, so the world size is 16000x16000
          spawn-protection = 0;
        };
        jvmOpts = minecraftLib.aikarFlagsWith { memory = "5120M"; };

        symlinks = {
          "server-icon.png" = server-icon;
        } // minecraftLib.collectFilesAt modpack "mods";

        files =
          (minecraftLib.collectFilesAt modpack "config") //
          (minecraftLib.collectFilesAt modpack "journeymap");
      };

      systemd.services."minecraft-server-${serverName}" = {
        # environment = {
        #   NOTIFY_SOCKET = notifySocket;
        # };

        serviceConfig = {
          # Type = lib.mkForce "notify";
          # NotifyAccess = "all";
          # Restart = lib.mkForce "on-failure";
          TimeoutStartSec = "90s";
          # PIDFile = pidFile;
        };
      };
    }
    (lib.mkIf (config.services.minecraft-servers.enable && config.services.minecraft-servers.servers.${serverName}.enable) {
      custom = {
        networking.ports.tcp = {
          "minecraft-${serverName}-game" = { port = 25565; openFirewall = true; };
        };

        minecraft-servers.check.servers = {
          ${serverName} = {
            address = "127.0.0.1";
            port = config.custom.networking.ports.tcp."minecraft-${serverName}-game".port;

            notify = {
              # socket = notifySocket;
              pidPath = pidFile;
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
