{
  config,
  ...
}:
{
  # Allow olivetin to manage systemd units so that it can start/stop/restart services.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units" && subject.user === "${config.services.olivetin.user}") {
        return polkit.Result.YES;
      }
    });
  '';
}
