{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/paperless";
  # externalRoot = "/mnt/external/paperless-library";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"

    "export"

    "postgresql"

    "redis"
  ];
  # ++ (lib.map (folder: "${externalRoot}/${folder}") [
  #   "media"
  # ]);

  foldersToSetPermissions = [
    storeRoot
    # externalRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-paperless-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-paperless-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
