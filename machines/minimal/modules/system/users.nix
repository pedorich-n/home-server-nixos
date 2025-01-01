{ lib, ... }:
let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP pedorich.n@gmail.com";
in
{
  users = {
    mutableUsers = false;
    users = {
      root = {
        password = "nixos";
        # Installation base makes the password empty: https://github.com/NixOS/nixpkgs/blob/de986200b9cb45d2210d7b760ec31a317d20933c/nixos/modules/profiles/installation-device.nix#L40
        # I prefer the explicitly set password here
        initialHashedPassword = lib.mkForce null;
        openssh.authorizedKeys.keys = [
          sshKey
        ];
      };
    };
  };
}
