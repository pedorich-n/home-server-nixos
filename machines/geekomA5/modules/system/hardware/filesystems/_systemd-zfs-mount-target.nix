{ config, lib, pkgs }:
{ dataset, restartTimetout ? "15s", numberOfRetries ? 5 }:
let
  sanitezedDataset = lib.strings.sanitizeDerivationName dataset;
in
{
  "zfs-mounted-${sanitezedDataset}" = {
    description = "ZFS dataset ${dataset} is mounted";
    wants = [ "zfs.target" ];

    startLimitBurst = numberOfRetries;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "zfs-mounted-check-${sanitezedDataset}";
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
