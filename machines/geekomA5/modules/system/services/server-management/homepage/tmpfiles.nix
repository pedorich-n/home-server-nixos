{ inputs, config, jinja2RendererLib, ... }:
let
  renderedConfig = import ./_render-config.nix { inherit jinja2RendererLib; };
in
{
  systemd.tmpfiles.settings."90-homepage" = {
    "/mnt/store/server-management/homepage/config" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${./static}";
      };
    };
    "/mnt/store/server-management/homepage/config/services.yaml" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${renderedConfig}/services.yaml";
      };
    };
    # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
    "/mnt/store/server-management/homepage/config/*" = {
      "z" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
      };
    };
    "/mnt/store/server-management/homepage/images/wallpaper.jpeg" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${inputs.homer-theme}/assets/wallpaper-light.jpeg";
      };
    };
  };
}
