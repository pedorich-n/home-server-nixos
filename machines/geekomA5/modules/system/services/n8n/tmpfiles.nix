{ tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/n8n";

  foldersToCreate = [
    storeRoot
  ];

  foldersToSetPermissions = [
    storeRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-n8n-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-n8n-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
