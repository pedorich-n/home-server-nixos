{
  writers,
  linkFarmFromDrvs,
  lib,
}:

let
  mkLanguageCustomFormat = name: id: {
    trash_id = "my-${lib.strings.toLower name}-language";
    name = "Language: ${name}";
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

  mkNotLanguageCustomFormat = name: id: {
    trash_id = "my-not-${lib.strings.toLower name}-language";
    name = "Language: Not ${name}";
    specifications = [
      {
        inherit name;
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
    English = 1;
    Russian = 11;
    Ukrainian = 30;
  };

  languageCustomFormats = lib.mapAttrsToList (
    name: id: writers.writeJSON "recyclarr-custom-format-${lib.toLower name}.json" (mkLanguageCustomFormat name id)
  ) languages;

  notLanguageCustomFormats = lib.mapAttrsToList (
    name: id: writers.writeJSON "recyclarr-custom-format-not-${lib.toLower name}.json" (mkNotLanguageCustomFormat name id)
  ) languages;
in
linkFarmFromDrvs "recyclarr-language-custom-formats" (
  lib.flatten [
    languageCustomFormats
    notLanguageCustomFormats
  ]
)
