{
  boot.initrd.systemd.tmpfiles.settings = {
    # From https://github.com/systemd/systemd/blob/df5dd059/tmpfiles.d/var.conf.in#L10
    "90-var" = {
      "/var".q.mode = "0755";
      "/var/run".L.argument = "/run";
    };
  };
}
