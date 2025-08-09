{ config, containerLib, ... }:
let
  storeRoot = "/mnt/store/core-keeper-servers/underground-monkeys";

  mappedVolumeForUser =
    localPath: remotePath:
    containerLib.mkIdmappedVolume {
      uidHost = config.users.users.user.uid;
      gidHost = config.users.groups.${config.users.users.user.group}.gid;
    } localPath remotePath;
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
        (mappedVolumeForUser "${storeRoot}/server-data" "/home/steam/core-keeper-data")
        (mappedVolumeForUser "${storeRoot}/server-files" "/home/steam/core-keeper-dedicated")
      ];
    };
  };

}
