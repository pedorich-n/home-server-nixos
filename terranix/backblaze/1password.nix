{ lib, ... }:
let
  mkItem = title: {
    ${lib.toLower title} = {
      vault = "homelab";
      inherit title;
    };
  };
in
{
  custom.onepassword = {
    enable = true;

    vaults = {
      homelab.name = "HomeLab";
    };

    items = lib.foldl' (acc: title: acc // (mkItem title)) { } [ "Backblaze_Terranix" "Backblaze_Bucket_Names" ];
  };
}
