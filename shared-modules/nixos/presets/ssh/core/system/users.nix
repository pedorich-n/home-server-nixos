{ config, ... }:
{
  users.users.root.openssh.authorizedKeys.keys = config.custom.ssh.keys;
}
