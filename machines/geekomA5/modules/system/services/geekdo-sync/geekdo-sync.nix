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
      GRIST_BASE_URL = networkingLib.mkUrl "grist";
      GRIST_DOC_ID = "oZY1tkbiXKPZGLjBFbbwBc";

      LOGGING_LEVEL = "DEBUG";
    };
    environmentFiles = [ config.sops.secrets."geekdo-sync/main.env".path ];

    timerConfig = {
      OnCalendar = "Mon *-*-* 02:00:00"; # Every Monday at 2 AM
      Persistent = true;
    };
  };
}
