{ lib, ... }: {
  services.openssh = {
    enable = lib.mkDefault true;
    settings.PasswordAuthentication = lib.mkDefault true;
  };
}
