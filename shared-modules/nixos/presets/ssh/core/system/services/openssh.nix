{ lib, ... }: {
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = lib.mkDefault true;
      PermitRootLogin = lib.mkDefault "prohibit-password";
    };
  };
}
