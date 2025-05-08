{
  boot.initrd.systemd.tmpfiles.settings = {
    "90-var" = {
      "/var" = {
        q = {
          mode = "0755";
        };
      };

      "/var/run" = {
        L = {
          argument = "/run";
        };
      };

      "/var/lib" = {
        d = {
          mode = "0755";
        };
      };

      "/var/cache" = {
        d = {
          mode = "0755";
        };
      };
    };
  };
}
