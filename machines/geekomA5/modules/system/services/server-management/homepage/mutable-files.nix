{ inputs, config, jinja2RendererLib,... }:
let
  entryFor = source: target: {
    name = "/mnt/store/server-management/homepage/${target}";
    value = {
      inherit source;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };

  renderedConfig = import ./_render-config.nix { inherit jinja2RendererLib; };
in
{
  environment.mutable-files = builtins.listToAttrs [
    (entryFor "${inputs.homer-theme}/assets/wallpaper-light.jpeg" "images/wallpaper.jpeg")
    (entryFor ./static/bookmarks.yaml "config/bookmarks.yaml")
    (entryFor ./static/custom.css "config/custom.css")
    (entryFor ./static/docker.yaml "config/docker.yaml")
    (entryFor ./static/settings.yaml "config/settings.yaml")
    (entryFor ./static/widgets.yaml "config/widgets.yaml")
    (entryFor "${renderedConfig}/services.yaml" "config/services.yaml")
  ];
}
