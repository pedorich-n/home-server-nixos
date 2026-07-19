{
  networkingLib,
  tmpfilesLib,
  config,
  pkgs,
  ...
}:
let
  renderedTemplates = pkgs.callPackage ./_render-templates.nix {
    inherit networkingLib;
    trustedProxies = config.virtualisation.quadlet.networks."home-automation-internal".networkConfig.subnets;
  };

  mergedHaSource = pkgs.runCommand "merged-ha-source" { } ''
    mkdir -p $out
    cp -rL --no-preserve=mode ${renderedTemplates}/. $out/
    cp -rL --no-preserve=mode ${./static}/. $out/
  '';
in
{
  systemd.tmpfiles.settings = {
    "90-homeassistant" = {
      "/mnt/store/home-automation/homeassistant" = {
        "C+" = tmpfilesLib.mkDefaultTmpDirectory "${mergedHaSource}";
      };
    };

    "91-homeassistant-set" = {
      # C+ rule for a folder doesn't apply the permissions to nested files. So an additional rule is needed.
      "/mnt/store/home-automation/homeassistant/*" = {
        "Z" = (tmpfilesLib.mkDefaultTmpDirectory "") // {
          mode = "0754";
        };
      };
    };
  };
}
