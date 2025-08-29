{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/home-automation";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "mosquitto/data"
    "mosquitto/log"

    "postgresql"

    "zigbee2mqtt"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-home-automation-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-home-automation-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
