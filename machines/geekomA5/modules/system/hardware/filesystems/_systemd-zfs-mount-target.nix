{ config, lib, pkgs }:
{ dataset, restartTimetout ? "15s", numberOfRetries ? 5 }:
let
  sanitizedDataset = lib.strings.sanitizeDerivationName dataset;
in
{
  "zfs-mounted-${sanitizedDataset}" = {
    description = "ZFS dataset ${dataset} is mounted";
    requires = [
      "zfs-mount.service"
    ];
    after = [
      "zfs-mount.service"
    ];

    startLimitBurst = numberOfRetries;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "zfs-mounted-check-${sanitizedDataset}";
        runtimeInputs = [ config.boot.zfs.package pkgs.gnugrep ];
        text = ''
          zfs get -H mounted ${dataset} | grep "yes"
        '';
      });

      Restart = "on-failure";
      RestartSec = restartTimetout;
    };
  };
}
