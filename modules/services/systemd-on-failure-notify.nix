{ config, lib, pkgs, ... }:
let
  unitName = "on-failure-notify@";

  # From https://discourse.nixos.org/t/how-to-use-toplevel-overrides-for-systemd/12501/4
  systemdOverride = pkgs.writeTextDir "/etc/systemd/system/service.d/10-on-failure-notify.conf" ''
    [Unit]
    OnFailure=${unitName}%N.service
  '';
in
{
  systemd = {
    packages = [ systemdOverride ];

    services."${unitName}" = {
      description = "Sends a notification on Systemd service failures";
      onFailure = lib.mkForce [ ];

      unitConfig = {
        StartLimitIntervalSec = "5m";
        StartLimitBurst = 1;
      };

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.systemd-onfailure-notify} --apprise-config ${config.age.secrets.apprise-config.path} --unit %i";
        Type = "oneshot";
      };
    };
  };
}
