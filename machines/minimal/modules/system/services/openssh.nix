{
  lib,
  ...
}:
{
  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "yes"; # Allow root login with password
  };
}
