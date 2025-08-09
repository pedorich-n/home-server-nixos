{
  flake,
  inputs,
  config,
  lib,
  pkgs-unstable,
  ...
}:
let
  uniqueListOf =
    elemType:
    let
      type = (lib.types.listOf elemType) // {
        name = "uniqueListOf";
        description = "unique list of ${lib.types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
      };
    in
    lib.types.addCheck type (l: lib.lists.allUnique l);

  sharedHomeManagerModules = flake.lib.loaders.listFilesRecursively {
    src = "${flake}/shared-modules/home-manager";
  };

  hmForUser =
    username:
    let
      path = "${flake}/homes/${username}";
    in
    lib.throwIfNot (builtins.pathExists path) "User '${username}' doesn't have a HomeManager config defined!" {
      imports = flake.lib.loaders.listFilesRecursively { src = path; };
    };

  enabledHmUsers = lib.foldl' (acc: user: acc // { ${user} = hmForUser user; }) { } config.custom.users.homeManagerUsers;
in
{
  options = {
    custom.users.homeManagerUsers = lib.mkOption {
      type = uniqueListOf lib.types.str;
      default = [ ];
      description = ''Enables HM for these users.'';
    };
  };

  config = lib.mkIf (enabledHmUsers != { }) {
    home-manager = {
      # Install HM into `/etc/profiles` rather than `$HOME/.nix-profile`.
      # Not sure if this needed, but HM docs say that it might be enabled by default in the future, so I assume it's better to enable it.
      useUserPackages = true;
      # Reuse NixOS's pkgs. "Saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH" - HM manual
      useGlobalPkgs = true;
      # File extension to add to backuped files
      backupFileExtension = "bak";

      extraSpecialArgs = {
        inherit flake inputs pkgs-unstable;
      };

      sharedModules = [
        inputs.home-manager-config.homeModules.sharedModules
      ]
      ++ sharedHomeManagerModules;

      users = enabledHmUsers;
    };
  };
}
