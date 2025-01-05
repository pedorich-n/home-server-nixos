{ domain, lib, ... }:
let
  mkArrProvider = name: {
    ${name} = {
      url = "http://${name}.${domain}";
      api_key = lib.tfRef ''var.arrs["${name}"]'';
    };
  };
in
{
  provider = lib.foldl' (acc: name: acc // (mkArrProvider name)) { } [ "prowlarr" "radarr" "sonarr" ];
}
