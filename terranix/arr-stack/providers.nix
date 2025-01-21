{ domain, lib, ... }:
let
  mkArrProvider = name: {
    ${name} = {
      url = "http://${name}.${domain}";
      api_key = lib.tfRef "local.secrets.${name}.API.key";
    };
  };
in
{
  provider = lib.foldl' (acc: name: acc // (mkArrProvider name)) { } [ "prowlarr" "radarr" "sonarr" ];
}
