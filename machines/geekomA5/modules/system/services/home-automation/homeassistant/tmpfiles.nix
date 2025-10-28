{
  networkingLib,
  tmpfilesLib,
  pkgs,
  ...
}:
let
  rendered-templates = pkgs.callPackage ./_render-templates.nix { inherit networkingLib; };
in
{
  systemd.tmpfiles.settings."90-homeassistant" = {
    "/mnt/store/home-automation/homeassistant" = {
      "C+" = tmpfilesLib.mkDefaultTmpDirectory "${./static}";
    };
    "/mnt/store/home-automation/homeassistant/dashboards/main.yaml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${rendered-templates}/dashboards/main.yaml";
    };
    "/mnt/store/home-automation/homeassistant/configuration.yaml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${rendered-templates}/configuration.yaml";
    };
    # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
    "/mnt/store/home-automation/homeassistant/*" = {
      "Z" = (tmpfilesLib.mkDefaultTmpDirectory "") // {
        mode = "0754";
      };
    };
  };
}
