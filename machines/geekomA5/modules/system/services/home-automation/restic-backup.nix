{ lib, ... }:
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic.nix
  services.restic.backups = {
    homeassistant = {
      paths = lib.map (rel: "/mnt/store/home-automation/homeassistant/${rel}") [
        "automations"
        "configuration"
        "custom_components"
        "deps"
        "local"
        "resources"
        ".storage"
        "themes"
        "ui_lovelace_minimalist"
        "www"
        "automations.yaml"
        "configuration.yaml"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };
}
