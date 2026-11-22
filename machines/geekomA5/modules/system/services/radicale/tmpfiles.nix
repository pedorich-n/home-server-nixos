{
  config,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/radicale";

  rule = {
    user = config.users.users.radicale.name;
    group = config.users.groups.radicale.name;
    mode = "0750";
  };
in
{
  systemd.tmpfiles.settings = {
    "90-radicale-create" = tmpfilesLib.applyRuleToFolders { "d" = rule; } [
      "${storeRoot}/collections"
    ];
    "91-radicale-set" = tmpfilesLib.applyRuleToFolders { "Z" = rule; } [
      storeRoot
    ];
  };
}
