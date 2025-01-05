{ lib, ... }: {
  options = {
    custom.ssh.keys = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      description = ''
        A list of SSH keys I use to connect to remote machines
      '';
      readOnly = true;
    };
  };

  config = {
    custom.ssh.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP Main"
    ];
  };
}
