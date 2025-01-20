{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
  _module.args.customLib = {
    mkOnePasswordMapping = item: tfRef ''{ 
      for section in data.onepassword_item.${item}.section: section.label => {
        for field in section.field: field.label => field.value
      } 
    }'';
  };
}
