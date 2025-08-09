{ lib, ... }:
{
  custom.systemd.on-failure-notify = {
    enable = lib.mkDefault true;
    enableForUnits = lib.mkDefault [
      {
        unitType = "service";
        priority = 50;
      }
      {
        unitType = "timer";
        priority = 50;
      }
    ];
  };
}
