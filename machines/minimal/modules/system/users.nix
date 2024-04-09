let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP pedorich.n@gmail.com";
in
{
  users = {
    mutableUsers = false;
    users = {
      root = {
        password = "nixos";
        openssh.authorizedKeys.keys = [
          sshKey
        ];
      };

      user = {
        uid = 1000;
        isNormalUser = true;
        useDefaultShell = true;
        password = "nixos";
        extraGroups = [
          "wheel"
          "systemd-journal"
          "plugdev"
        ];
        openssh.authorizedKeys.keys = [
          sshKey
        ];
      };
    };
  };
}
