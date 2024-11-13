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
    {
      apprise_config = useDefault;
      root_password_hashed = useDefault;
      user_password_hashed = useDefault;
      server_check_config = useDefault;
    } //
    (lib.optionalAttrs (builtins.hasAttr "playit" config.services && config.services.playit.enable) {
      playit_secret = mapping: mapping // { owner = config.services.playit.user; inherit (config.services.playit) group; };
    }) //
    (lib.optionalAttrs (builtins.hasAttr "ngrok" config.services && config.services.ngrok.enable) {
      ngrok = mapping: mapping // { owner = config.services.ngrok.user; inherit (config.services.ngrok) group; };
    }) //
    (lib.optionalAttrs config.services.netdata.enable {
      netdata_telegram_notify = mapping: mapping // { owner = config.services.netdata.user; inherit (config.services.netdata) group; };
    });

  mkSecret = path:
    let
      removeExtensionFromFilename = filename: builtins.head (builtins.match "([^.]+).*" filename);
      name = removeExtensionFromFilename (getFilename path);

      override = mappingOverrides.${name} or lib.id;
      mapping = mkMapping path override;
    in
    { ${name} = mapping; };


  encryptedFilesToMount = builtins.filter (path: lib.hasSuffix ".age" path) (lib.filesystem.listFilesRecursive "${inputs.home-server-nixos-secrets}/encrypted");

  secrets = lib.mkMerge (builtins.map (path: mkSecret path) encryptedFilesToMount);
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age = {
    inherit secrets;
  };
}
