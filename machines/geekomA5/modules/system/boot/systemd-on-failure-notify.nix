{ pkgs-unstable, ... }: {
  # See https://github.com/nix-community/poetry2nix/pull/1559#issuecomment-2089910134
  custom.systemd.on-failure-notify.package = pkgs-unstable.systemd-onfailure-notify;
}
