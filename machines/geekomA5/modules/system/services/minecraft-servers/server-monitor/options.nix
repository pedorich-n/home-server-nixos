{ lib, ... }:
let

  serverSubmodule = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 25565;
      };

      notify = {
        # socket = lib.mkOption {
        #   type = lib.types.path;
        # };
        pidPath = lib.mkOption {
          type = lib.types.path;
        };

        intervalSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 60;
        };
      };

      healthCheck = {
        retries = lib.mkOption {
          type = lib.types.ints.positive;
          default = 15;
        };

        intervalSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 5;
        };
      };

    };
  };

in

{
  options = {
    custom.minecraft-servers.check = {
      enable = lib.mkEnableOption "Minecraft Servers health check";
      servers = lib.mkOption {
        type = lib.types.attrsOf serverSubmodule;
        default = { };
      };
    };
  };
}
