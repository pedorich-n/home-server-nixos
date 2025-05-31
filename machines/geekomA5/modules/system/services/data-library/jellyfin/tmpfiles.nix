{ pkgs, networkingLib, tmpfilesLib, ... }:
let
  branding-config = pkgs.callPackage ./_branding-config.nix { inherit networkingLib; };
in
{
  systemd.tmpfiles.settings."90-jellyfin" = {
    "/mnt/store/data-library/jellyfin/config/config/branding.xml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${branding-config}";
    };
  };
}
