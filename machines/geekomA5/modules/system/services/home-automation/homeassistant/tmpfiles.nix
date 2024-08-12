{ jinja2RendererLib, tmpfilesLib, ... }:
let
  rendered-templates = import ./_render-templates.nix { inherit jinja2RendererLib; };
in
{
  systemd.tmpfiles.settings."90-homeassistant" = {
    "/mnt/store/home-automation/homeassistant" = {
      "C+" = tmpfilesLib.mkDefaultTmpDirectory "${./static}";
    };
    "/mnt/store/home-automation/homeassistant/ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${rendered-templates}/ui_lovelace_minimalist/dashboard/ui-lovelace-custom-grid.yaml";
    };
    # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
    "/mnt/store/home-automation/homeassistant/*" = {
      "Z" = (tmpfilesLib.mkDefaultTmpDirectory "") // { mode = "0754"; };
    };
  };
}
