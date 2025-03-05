{ tmpfilesLib, pkgs, ... }:
let
  rendered-templates = pkgs.callPackage ./_render-templates.nix { };
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
