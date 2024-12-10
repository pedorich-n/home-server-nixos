{ flake, inputs, config, lib, ... }:
let
  sharedHomeManagerModules = flake.lib.loaders.listFilesRecursivelly { src = "${flake}/shared-modules/home-manager"; };

  hmForUser = username:
    let
      path = "${flake}/homes/${username}";
    in
    lib.throwIfNot (builtins.pathExists path) "User '${username}' doesn't have a HomeManager config defined!" {
      imports = flake.lib.loaders.listFilesRecursivelly { src = path; };
    };

  #LINK - shared-modules/nixos/custom/system/users.nix
  enabledHmUsers = lib.foldl' (acc: user: acc // { ${user} = hmForUser user; }) { } config.custom.users.homeManagerUsers;
in
{
  home-manager = lib.mkIf (enabledHmUsers != { }) {
    # Install HM into `/etc/profiles` rather than `$HOME/.nix-profile`. 
    # Not sure if this needed, but HM docs say that it might be enabled by default in the future, so I assume it's better to enable it.
    useUserPackages = true;
    # Reuse NixOS's pkgs. "Saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH" - HM manual
    useGlobalPkgs = true;
    # File extension to add to backuped files
    backupFileExtension = ".bak";

    extraSpecialArgs = { inherit flake inputs; };

    sharedModules = [ inputs.personal-home-manager.homeModules.sharedModules ] ++ sharedHomeManagerModules;

    users = enabledHmUsers;
  };
}
