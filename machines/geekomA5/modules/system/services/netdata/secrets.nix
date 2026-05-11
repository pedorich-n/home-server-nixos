{
  config,
  ...
}:
{
  sops.templates = {
    "netdata/health_alarm_notify.conf" = {
      owner = config.services.netdata.user;
      group = config.services.netdata.group;
      mode = "0660";
      content = ''
        SEND_TELEGRAM="YES"
        TELEGRAM_BOT_TOKEN="${config.sops.placeholder."netdata/notifications/telegram/bot_token"}"
        DEFAULT_RECIPIENT_TELEGRAM="${config.sops.placeholder."netdata/notifications/telegram/recipient"}"
      '';
    };
  };
}
