{
  # NOTE Caused by `libpod-<id>.scope` and `libpod-conmon-<id>.scope` units delaying the shutdown. 
  # It's not clear what exactly causes it, see https://github.com/containers/podman/issues/19815 
  # Because non-service systemd units don't have their own timeout I am forced to set this default value
  # See https://github.com/systemd/systemd/issues/13871#issuecomment-547820111 & https://github.com/systemd/systemd/issues/8395
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30
  '';
}
