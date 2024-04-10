{ config, inputs, ... }:
let
  entryFor = source: target: {
    name = "/mnt/store/home-automation/homer/${target}";
    value = {
      inherit source;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };
in
{
  environment.mutable-files = builtins.listToAttrs [
    (entryFor "${inputs.homer-theme}/assets/fonts" "fonts")
    (entryFor "${inputs.homer-theme}/assets/custom.css" "custom.css")
    (entryFor "${inputs.homer-theme}/assets/wallpaper-light.jpeg" "wallpaper-light.jpeg")
    (entryFor "${inputs.homer-theme}/assets/wallpaper.jpeg" "wallpaper.jpeg")
    (entryFor ./config.yml "config.yml")
  ];
}
