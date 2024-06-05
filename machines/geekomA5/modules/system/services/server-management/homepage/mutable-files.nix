{ inputs, config, lib, pkgs, ... }:
let
  entryFor = source: target: {
    name = "/mnt/store/server-management/homepage/${target}";
    value = {
      inherit source;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };

  renderedConfig = import ./_render-config.nix { inherit config lib pkgs; };
in
{
  environment.mutable-files = builtins.listToAttrs [
    (entryFor "${inputs.homer-theme}/assets/wallpaper.jpeg" "images/wallpaper.jpeg")
    (entryFor renderedConfig "config")
  ];
}
