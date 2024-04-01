{ config, lib, pkgs, ... }:
let
  unitName = "on-failure-notify@";

  # From https://discourse.nixos.org/t/how-to-use-toplevel-overrides-for-systemd/12501/4
  systemdOverrides =
    let
      mkOverride = unitType: pkgs.writeTextDir "/etc/systemd/system/${unitType}.d/50-on-failure-notify.conf" ''
        [Unit]
        OnFailure=${unitName}%N.service
      '';
    in
    builtins.map mkOverride [ "service" "timer" ];
in
{
  systemd = {
    packages = systemdOverrides;

    services."${unitName}" = {
      description = "Sends a notification on Systemd service failures";
      onFailure = lib.mkForce [ ];

      unitConfig = {
        StartLimitIntervalSec = "5m";
        StartLimitBurst = 1;
      };

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.systemd-onfailure-notify} --apprise-config ${config.age.secrets.apprise_config.path} --unit %i";
        Type = "oneshot";
      };
    };
  };
}
