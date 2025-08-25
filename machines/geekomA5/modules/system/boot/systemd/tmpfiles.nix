let
  after = [ "zfs-mount.service" ];
  wants = [ "zfs-mount.service" ];
in
{
  systemd.services = {
    systemd-tmpfiles-setup = {
      inherit after wants;
    };

    systemd-tmpfiles-resetup = {
      inherit after wants;
    };
  };
}
