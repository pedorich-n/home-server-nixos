{ config, inputs, lib, ... }:
let
  inherit (builtins) unsafeDiscardStringContext baseNameOf head match replaceStrings removeAttrs hasAttr getAttr filter listToAttrs map;

  getBaseName = path: unsafeDiscardStringContext (baseNameOf path);

  getAttrName =
    let
      removeExtensionFromFilename = filename: head (match "([^.]+).*" filename);
      replaceUnderscores = str: replaceStrings [ "_" ] [ "-" ] str;
    in
    path: lib.pipe path [ getBaseName removeExtensionFromFilename replaceUnderscores ];


  mkMapping = path: override: override {
    file = path;
    name = lib.removeSuffix ".age" (getBaseName path);
    mode = "440";
    owner = config.users.users.user.name;
    group = config.users.users.user.group;
  };

  customMappings =
    let
      useDefaultOwner = mapping: removeAttrs mapping [ "mode" "owner" "group" ];
    in
    {
      "root_password.txt.age" = useDefaultOwner;
      "user_password.txt.age" = useDefaultOwner;
      "server_check_config.toml.age" = useDefaultOwner;
      "playit_secret.toml.age" = mapping: mapping // { owner = "playit"; group = "playit"; };
    };

  mkMappingWithOverride = path:
    let
      baseName = getBaseName path;
      override = if (hasAttr baseName customMappings) then (getAttr baseName customMappings) else lib.id;
      mapping = mkMapping path override;
    in
    mapping;


  rootEncrypted = "${inputs.home-server-nixos-secrets}/encrypted";
  allEncrypted = filter (path: lib.hasSuffix ".age" path) (lib.filesystem.listFilesRecursive rootEncrypted);

  secrets = listToAttrs (map (path: { name = getAttrName path; value = mkMappingWithOverride path; }) allEncrypted);
in
{
  age = {
    inherit secrets;
  };
}
