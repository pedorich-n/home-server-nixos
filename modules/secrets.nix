{ config, inputs, lib, ... }:
let
  inherit (builtins) unsafeDiscardStringContext baseNameOf head match removeAttrs filter listToAttrs map;
  inherit (lib) removeSuffix;

  getFilename = path: unsafeDiscardStringContext (baseNameOf path);

  mkMapping = path: override: override {
    file = path;
    name = removeSuffix ".age" (getFilename path);
    mode = "440";
    owner = config.users.users.user.name;
    group = config.users.users.user.group;
  };

  mappingOverrides =
    let
      useDefault = mapping: removeAttrs mapping [ "mode" "owner" "group" ];
    in
    {
      apprise_config = useDefault;
      root_password_hashed = useDefault;
      user_password_hashed = useDefault;
      server_check_config = useDefault;
      ngrok = mapping: mapping // { owner = "ngrok"; group = "ngrok"; };
      playit_secret = mapping: mapping // { owner = "playit"; group = "playit"; };
    };

  mkSecret = path:
    let
      removeExtensionFromFilename = filename: head (match "([^.]+).*" filename);
      name = removeExtensionFromFilename (getFilename path);

      override = mappingOverrides.${name} or lib.id;
    in
    {
      inherit name;
      value = mkMapping path override;
    };

  allEncrypted = filter (path: lib.hasSuffix ".age" path) (lib.filesystem.listFilesRecursive "${inputs.home-server-nixos-secrets}/encrypted");

  secrets = listToAttrs (map (path: mkSecret path) allEncrypted);
in
{
  age = {
    inherit secrets;
  };
}
