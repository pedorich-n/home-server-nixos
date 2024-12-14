let
  sensitiveString = {
    type = "string";
    sensitive = true;
  };
in
{
  variable = {
    "prowlarr_api_key" = sensitiveString;

    "radarr_api_key" = sensitiveString;

    "sonarr_api_key" = sensitiveString;

    "indexers" = {
      type = "map(string)";
      sensitive = true;
    };
  };
}
