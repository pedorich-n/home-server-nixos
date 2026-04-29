{
  config,
  pkgs,
  ...
}:
let
  filename = "systemd-on-failure-notify.yaml";
in
{
  sops.templates.${filename}.file = pkgs.writers.writeYAML filename {
    urls = [
      config.sops.placeholder."apprise/urls/telegram"
    ];
  };

  custom.systemd.on-failure-notify.appriseConfigPath = config.sops.templates.${filename}.path;
}
