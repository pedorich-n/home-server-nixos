{
  config,
  networkingLib,
  systemdLib,
  ...
}:
{
  systemd.services.book-sync.unitConfig = systemdLib.requiresAfter [
    "grist.service"
  ];

  services.book-sync = {
    enable = true;
    environment = {
      ABS_BASE_URL = networkingLib.mkUrl "audiobookshelf";

      GRIST_BASE_URL = networkingLib.mkUrl "grist";
      GRIST_DOC_ID = "9yk1ZQFq5UwDfxeyL1o3eX";

      LOGGING_LEVEL = "DEBUG";
    };
    environmentFiles = [ config.sops.secrets."book-sync/main.env".path ];

    timerConfig = {
      OnCalendar = "*-*-* *:00:00"; # Every hour
      Persistent = true;
    };
  };
}
