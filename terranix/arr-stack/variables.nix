let
  sensitiveMap = {
    type = "map(string)";
    sensitive = true;
  };
in
{
  variable = {
    arrs = sensitiveMap;
    indexers = sensitiveMap;
    downloaders = sensitiveMap;
  };
}
