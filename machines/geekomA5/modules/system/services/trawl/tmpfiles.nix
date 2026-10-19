{
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/trawl";

  foldersToCreate = [
    storeRoot
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-trawl-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-trawl-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
