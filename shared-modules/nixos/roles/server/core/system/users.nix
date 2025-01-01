let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP pedorich.n@gmail.com";
in
{
  users.users.root.openssh.authorizedKeys.keys = [ sshKey ];
}
