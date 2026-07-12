{
  writers,
  linkFarmFromDrvs,
  lib,
}:

let
  mkNotLanguageCustomFormat = name: id: {
    trash_id = "my-not-${lib.strings.toLower name}-language";
    name = "Language: Not ${name}";
    trash_scores = {
      default = -10000;
    };
    specifications = [
      {
        name = "Not ${name} Language (custom)";
        implementation = "LanguageSpecification";
        negate = true;
        required = true;
        fields = {
          value = id;
        };
      }
    ];
  };

  languages = {
    # English = 1;
    Russian = 11;
    Ukrainian = 30;
  };

  notLanguageCustomFormats = lib.mapAttrsToList (
    name: id: writers.writeJSON "recyclarr-custom-format-not-${lib.toLower name}.json" (mkNotLanguageCustomFormat name id)
  ) languages;
in
linkFarmFromDrvs "recyclarr-language-custom-formats" notLanguageCustomFormats
