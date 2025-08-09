{ lib, tmpfilesLib, ... }:
let
  inherit (tmpfilesLib) mkDefaultCreateDirectoryRule mkDefaultSetPermissionsRule;

  storeRoot = "/mnt/store/paperless";
  externalRoot = "/mnt/external/paperless-library";

  foldersToCreate =
    (lib.map (folder: "${storeRoot}/${folder}") [
      "data"

      "export"

      "postgresql"

      "redis"
    ])
    ++ (lib.map (folder: "${externalRoot}/${folder}") [
      "media"
    ]);

  foldersToSetPermissions = [
    storeRoot
    externalRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-paperless-create" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultCreateDirectoryRule; }) { } foldersToCreate;
    "91-paperless-set" = lib.foldl' (acc: folder: acc // { ${folder} = mkDefaultSetPermissionsRule; }) { } foldersToSetPermissions;
  };
}
