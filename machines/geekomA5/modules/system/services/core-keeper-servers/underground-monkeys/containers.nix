{ config, containerLib, ... }:
let
  storeRoot = "/mnt/store/core-keeper-servers/underground-monkeys";
in
{
  virtualisation.quadlet.containers.core-keeper-server = {
    useGlobalContainers = true;
    usernsAuto = {
      enable = true;
      size = 65535;
    };

    containerConfig = {
      environments = {
        inherit (containerLib.containerIds) PUID PGID;

        WORLD_NAME = "Underground Monkeys";
        MAX_PLAYERS = "6";

        MODS_ENABLED = "false";
      };
      environmentFiles = [ config.sops.secrets."core-keeper/main.env".path ];
      volumes = [
        (containerLib.mkMappedVolumeForUser "${storeRoot}/server-data" "/home/steam/core-keeper-data")
        (containerLib.mkMappedVolumeForUser "${storeRoot}/server-files" "/home/steam/core-keeper-dedicated")
      ];
    };
  };

}
