{ inputs, jinja2RendererLib, tmpfilesLib, ... }:
let
  renderedConfig = import ./_render-config.nix { inherit jinja2RendererLib; };
in
{
  systemd.tmpfiles.settings."90-homepage" = {
    "/mnt/store/server-management/homepage/config" = {
      "C+" = tmpfilesLib.mkDefaultTmpDirectory "${./static}";
    };
    "/mnt/store/server-management/homepage/config/services.yaml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${renderedConfig}/services.yaml";
    };
    # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
    "/mnt/store/server-management/homepage/config/*" = {
      "z" = tmpfilesLib.mkDefaultTmpFile "";
    };
    "/mnt/store/server-management/homepage/images/wallpaper.jpeg" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${inputs.homer-theme}/assets/wallpaper-light.jpeg";
    };
  };
}
