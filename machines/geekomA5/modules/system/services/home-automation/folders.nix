{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

  storeRoot = "/mnt/store/home-automation";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "homeassistant"

    "mosquitto"
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
    "90-home-automation-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-home-automation-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
