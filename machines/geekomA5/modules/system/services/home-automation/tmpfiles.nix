{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/home-automation";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "postgresql"
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-home-automation-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
  };
}
