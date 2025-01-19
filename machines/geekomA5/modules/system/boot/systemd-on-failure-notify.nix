{ config, pkgs, ... }:
let
  yamlFormat = pkgs.formats.yaml { };
  filename = "systemd-on-failure-notify.yaml";
in
{
  sops.templates.${filename}.file = yamlFormat.generate filename {
    urls = [
      config.sops.placeholder."apprise/urls/telegram"
    ];
  };

  custom.systemd.on-failure-notify.appriseConfigPath = config.sops.templates.${filename}.path;
}
