{
  lib,
  ...
}:
{
  systemd.enableEmergencyMode = lib.mkDefault true;
}
