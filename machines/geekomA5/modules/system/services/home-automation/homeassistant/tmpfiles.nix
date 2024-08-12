{ config, jinja2RendererLib, ... }:
let
  rendered-templates = import ./_render-templates.nix { inherit jinja2RendererLib; };
in
{
  systemd.tmpfiles.settings."90-homeassistant" = {
    "/mnt/store/home-automation/homeassistant" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${./static}";
      };
    };
    "/mnt/store/home-automation/homeassistant/ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${rendered-templates}/ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml";
      };
    };
    # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
    "/mnt/store/home-automation/homeassistant/*" = { 
      "Z" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
      };
    };
  };
}
