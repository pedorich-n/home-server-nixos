{ lib }:
let
  serviceName = "on-failure-notify@";
in
{
  systemd.services."${serviceName}" = {
    description = "Sends a notification on SystemD service failures";
    onFailure = lib.mkForce [ ];
    unitConfig = {
      StartLimitIntervalSec = "5m";
      StartLimitBurst = 1;
    };
    serviceConfig = {
      # ExecCondition = "${checkConditions} %i";
      # ExecStart = "${sendmail} ${config.systemd.email-notify.mailTo} %i";
      Type = "oneshot";
    };
  };
}
