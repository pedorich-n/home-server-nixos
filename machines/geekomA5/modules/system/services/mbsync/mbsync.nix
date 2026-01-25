{
  config,
  ...
}:
{
  custom.services.mbsync = {
    enable = true;

    configFile = config.sops.templates."mbsyncrc".path;
    localMailboxes = [ "/mnt/store/mail/archive" ];
    verbose = true;
  };
}
