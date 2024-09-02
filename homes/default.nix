{ flake, inputs, config, lib, ... }:
let
  sharedHomeManagerModules = flake.lib.loaders.listModules { src = ./modules; };

  hmUserProfiles = flake.lib.loaders.listNamedSubmodules { src = ./users; };
  hmForUser = username:
    if hmUserProfiles ? ${username} then { imports = hmUserProfiles.${username}; }
    else (builtins.abort "User '${username}' doesn't have a HomeManager config defined!");

  #LINK - modules/custom/system/users.nix
  enabledHmUsers = lib.foldl' (acc: user: acc // { ${user} = hmForUser user; }) { } config.custom.users.homeManagerUsers;
in
{
  home-manager = {
    # Install HM into `/etc/profiles` rather than `$HOME/.nix-profile`. 
    # Not sure if this needed, but HM docs say that it might be enabled by default in the future, so I assume it's better to enable it.
    useUserPackages = true;
    # Reuse NixOS's pkgs. "Saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH" - HM manual
    useGlobalPkgs = true;
    # File extension to add to backuped files
    backupFileExtension = ".bak";

    extraSpecialArgs = { inherit flake inputs; };

    sharedModules = inputs.personal-home-manager.homeModules.sharedModules ++ sharedHomeManagerModules;

    users = enabledHmUsers;
  };
}
