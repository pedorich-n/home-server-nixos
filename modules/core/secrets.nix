# WARN: Agenix will just skip a secret if it can't be decrypted or user/group doesn't exist
{ config, inputs, lib, ... }:
let
  getFilename = path: builtins.unsafeDiscardStringContext (builtins.baseNameOf path);

  mkMapping = path: override: override {
    file = path;
    name = lib.removeSuffix ".age" (getFilename path);
    mode = "440";
    owner = config.users.users.user.name;
    group = config.users.users.user.group;
  };

  mappingOverrides =
    let
      useDefault = mapping: builtins.removeAttrs mapping [ "mode" "owner" "group" ];
    in
    lib.mkMerge [
      {
        apprise_config = useDefault;
        root_password_hashed = useDefault;
        user_password_hashed = useDefault;
        server_check_config = useDefault;
      }
      (lib.mkIf (builtins.hasAttr "playit" config.services && config.services.playit.enable) {
        playit_secret_nucbox = mapping: mapping // { owner = config.services.playit.user; inherit (config.services.playit) group; };
        playit_secret_geekom = mapping: mapping // { owner = config.services.playit.user; inherit (config.services.playit) group; };
      })
      (lib.mkIf (builtins.hasAttr "ngrok" config.services && config.services.ngrok.enable) {
        ngrok = mapping: mapping // { owner = config.services.ngrok.user; inherit (config.services.ngrok) group; };
      })
    ];

  mkSecret = path:
    let
      removeExtensionFromFilename = filename: builtins.head (builtins.match "([^.]+).*" filename);
      name = removeExtensionFromFilename (getFilename path);

      override = mappingOverrides.${name} or lib.id;
      mapping = mkMapping path override;

      # Turns attrset of users into a list [{ name = <username>; uid = nullOr <uid>; }]
      usersNameUid = lib.mapAttrsToList (name: user: { inherit name; inherit (user) uid; }) config.users.users;
      isUsernameOrUidExists = usernameOrUid: lib.any ({ name, uid }: name == usernameOrUid || (uid != null && uid == usernameOrUid)) usersNameUid;
      userCheck = !config.users.mutableUsers &&
        (if (builtins.hasAttr "owner" mapping) then isUsernameOrUidExists mapping.owner else true);

      # Turns attrset of groups into a list [{ name = <groupname>; gid = nullOr <gid>; }]
      groupsNameGid = lib.mapAttrsToList (name: group: { inherit name; inherit (group) gid; }) config.users.groups;
      isGroupnameOrGidExists = groupnameOrGid: lib.any ({ name, gid }: name == groupnameOrGid || (gid != null && gid == groupnameOrGid)) groupsNameGid;
      groupCheck = !config.users.mutableUsers &&
        (if (builtins.hasAttr "group" mapping) then isGroupnameOrGidExists mapping.group else true);

      ownerAndGroupExists = userCheck && groupCheck;
    in
    if (!ownerAndGroupExists)
    then (lib.trace "Secrets: owner and/or group doesn't exist for '${mapping.name}'! Skipping." { })
    else { ${name} = mapping; };

  allEncrypted = builtins.filter (path: lib.hasSuffix ".age" path) (lib.filesystem.listFilesRecursive "${inputs.home-server-nixos-secrets}/encrypted");

  secrets = lib.mkMerge (builtins.map (path: mkSecret path) allEncrypted);
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age = {
    inherit secrets;
  };
}
