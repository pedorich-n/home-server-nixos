let
  defaultLocale = "en_US.UTF-8";

  extraLocaleVars = [ "LC_ADDRESS" "LC_IDENTIFICATION" "LC_MEASUREMENT" "LC_MONETARY" "LC_NUMERIC" "LC_PAPER" "LC_TIME" ];
  extraLocaleSettings = builtins.listToAttrs (builtins.map (localeVar: { name = localeVar; value = defaultLocale; }) extraLocaleVars);
in
{
  i18n = {
    inherit defaultLocale;
    inherit extraLocaleSettings;
  };

  time.timeZone = "Asia/Tokyo";
}
