{ systemdLib, ... }:
{
  systemd.services = {
    systemd-tmpfiles-setup.unitConfig = systemdLib.wantsAfter [ "zfs.target" ];

    systemd-tmpfiles-resetup.unitConfig = systemdLib.wantsAfter [ "zfs.target" ];
  };
}
