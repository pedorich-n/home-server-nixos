{
  config,
  ...
}:
{
  custom.services.mbsync = {
    enable = true;

    timerConfig = {
      OnCalendar = "*-*-* *:00,15,30,45:00"; # Every 15 minutes
      Persistent = true;
    };

    expungeNearTimer = {
      OnCalendar = "Sun *-*-* 04:00:00"; # Every Sunday 04:00
      Persistent = true;
    };

    configFile = config.sops.templates."mbsyncrc".path;
    localMailboxes = [ "/mnt/store/mail/archive" ];
    verbose = true;
  };
}
