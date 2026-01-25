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

    configFile = config.sops.templates."mbsyncrc".path;
    localMailboxes = [ "/mnt/store/mail/archive" ];
    verbose = true;
  };
}
