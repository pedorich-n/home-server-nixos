{ flake, lib, ... }:
let
  serverCfg = flake.nixosConfigurations.geekomA5.config;

  domain = serverCfg.custom.networking.domain;

  mkArrProvider = name: {
    ${name} = {
      url = "http://${name}.${domain}";
      api_key = "\${var.arrs[\"${name}\"]}";
    };
  };
in
{
  provider = lib.foldl' (acc: name: acc // (mkArrProvider name)) { } [ "prowlarr" "radarr" "sonarr" ];
}
