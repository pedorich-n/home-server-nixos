{
  config,
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/couchdb";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "data"
    "index"
  ];

  foldersToSetPermissions = [
    storeRoot
  ];

  rule = {
    user = config.services.couchdb.user;
    group = config.services.couchdb.group;
    mode = "0750";
  };
in
{
  systemd.tmpfiles.settings = {
    "90-couchdb-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } foldersToCreate;
    "91-couchdb-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } foldersToSetPermissions;
  };
}
