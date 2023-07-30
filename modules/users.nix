{ config, ... }: {
  # services.getty.autologinUser = "user";

  users = rec {
    groups = {
      zigbee = { };
      podman = { };
      docker = { };
    };

    mutableUsers = false;
    users = {
      root.passwordFile = config.age.secrets.root-password.path;

      user = {
        uid = 1000;
        isNormalUser = true;
        useDefaultShell = true;
        passwordFile = config.age.secrets.user-password.path;
        extraGroups = (builtins.attrNames groups) ++ [ "networkmanager" "systemd-journal" "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP pedorich.n@gmail.com"
        ];
      };
    };
  };
}
