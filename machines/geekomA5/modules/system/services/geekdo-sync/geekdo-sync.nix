{
  config,
  networkingLib,
  systemdLib,
  ...
}:
{
  systemd.services.geekdo-sync.unitConfig = systemdLib.requiresAfter [
    "grist.service"
  ];

  services.geekdo-sync = {
    enable = true;
    environment = {
      # See https://pygrister.readthedocs.io/en/latest/conf.html#configuration-keys
      GRIST_SELF_MANAGED = "Y";
      GRIST_SELF_MANAGED_SINGLE_ORG = "Y";
      GRIST_SELF_MANAGED_HOME = networkingLib.mkUrl "grist";

      GRIST_DOC_ID = "oZY1tkbiXKPZ";

      LOGGING_LEVEL = "DEBUG";
      LOGGING_FORMAT = "systemd";
    };
    environmentFiles = [ config.sops.secrets."geekdo-sync/main.env".path ];

    timerConfig = {
      OnCalendar = "Mon *-*-* 02:00:00"; # Every Monday at 2 AM
      Persistent = true;
    };
  };
}
