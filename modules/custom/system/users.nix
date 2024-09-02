{ lib, ... }:
let
  uniqueListOf = elemType:
    let
      type = (lib.types.listOf elemType) // {
        name = "uniqueListOf";
        description = "unique list of ${lib.types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
      };
    in
    lib.types.addCheck type (l: lib.lists.allUnique l);
in
{
  options = {
    custom.users.homeManagerUsers = lib.mkOption {
      type = uniqueListOf lib.types.str;
      default = [ ];
      description = ''Enables HM for these users.'';
    };
  };
}
