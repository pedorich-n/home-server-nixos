{
  writers,
  linkFarmFromDrvs,
  lib,
}:

let
  mkLanguageCustomFormat = name: id: {
    trash_id = "my-${lib.strings.toLower name}-language";
    name = "${name} Language";
    specifications = [
      {
        inherit name;
        implementation = "LanguageSpecification";
        negate = false;
        required = true;
        fields = {
          value = id;
        };
      }
    ];
  };

  languages = {
    English = 1;
    Russian = 11;
    Ukrainian = 30;
  };

  languageCustomFormats = lib.mapAttrsToList (
    name: id: writers.writeJSON "recyclarr-custom-format-${lib.toLower name}.json" (mkLanguageCustomFormat name id)
  ) languages;
in
linkFarmFromDrvs "recyclarr-language-custom-formats" languageCustomFormats
