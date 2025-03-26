{ config, lib, pkgs, ... }:
let
  cfg = config.custom.systemd.on-failure-notify;

  unitName = "on-failure-notify@";

  # Nix implementation from https://discourse.nixos.org/t/how-to-use-toplevel-overrides-for-systemd/12501/4
  systemdOverrides =
    let
      mkOverride = { unitType, priority }:
        pkgs.writeTextDir "/etc/systemd/system/${unitType}.d/${lib.fixedWidthNumber 2 priority}-on-failure-notify.conf" ''
          [Unit]
          OnFailure=${unitName}%N.service
        '';
    in
    builtins.map mkOverride cfg.enableForUnits;

  overrideUnitType = with lib; types.submodule {
    options = {
      unitType = mkOption {
        type = types.str;
        example = "services";
      };

      priority = mkOption {
        type = types.ints.between 0 100;
        default = 50;
      };
    };
  };
in
{
  options = {
    custom.systemd.on-failure-notify = {
      enable = lib.mkEnableOption "Systemd On Failure Notify" // {
        description = ''
          If systemd units fail, this service gets triggered and notifies the targets using the Apprise app.
          This modules utilizes what's called "Systemd Top-Level Drop-In Override" 
          to add `OnFailure` override to all units of the specified type(s) without modifying their Nix definition.
        '';
      };

      package = lib.mkPackageOption pkgs "systemd-onfailure-notify" { };

      enableForUnits = lib.mkOption {
        type = lib.types.listOf overrideUnitType;
      };

      appriseConfigPath = lib.mkOption {
        type = lib.types.path;
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
          ExecStart = "${lib.getExe cfg.package} --apprise-config ${cfg.appriseConfigPath} --unit %i";
          Type = "oneshot";
        };
      };
    };
  };

}
