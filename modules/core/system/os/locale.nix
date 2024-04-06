let
  defaultLocale = "en_US.UTF-8";

  extraLocaleVars = [
    "LANG"

    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MESSAGES"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
  ];
  extraLocaleSettings = builtins.listToAttrs (builtins.map (localeVar: { name = localeVar; value = defaultLocale; }) extraLocaleVars);
in
{
  i18n = {
    inherit defaultLocale;
    extraLocaleSettings = {
      "LC_TIME" = "en_GB.UTF-8"; # dd/MM/YYYY please
      "LC_MEASUREMENT" = "en_GB.UTF-8"; # Metric, please
    } // extraLocaleSettings;

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
    ];
  };



  time.timeZone = "Asia/Tokyo";
}
