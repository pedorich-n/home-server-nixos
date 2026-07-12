{
  config,
  pkgs,
  ...
}:
let
  languageCustomFormats = pkgs.callPackage ./_language-custom-formats.nix { };

  settingsDrv = pkgs.writers.writeYAML "recyclarr-settings.yml" {
    resource_providers = [
      {
        name = "custom-language-formats-radarr";
        type = "custom-formats";
        path = languageCustomFormats;
        service = "radarr";
      }
      {
        name = "custom-language-formats-sonarr";
        type = "custom-formats";
        path = languageCustomFormats;
        service = "sonarr";
      }
    ];
  };

  rule = {
    user = config.services.recyclarr.user;
    group = config.services.recyclarr.group;
    mode = "0775";
  };
in
{

  systemd.tmpfiles.settings = {
    "90-recyclarr-settings" = {
      "/var/lib/recyclarr/settings.yml" = {
        "L+" = rule // {
          argument = "${settingsDrv}";
        };
      };
    };
  };

}
