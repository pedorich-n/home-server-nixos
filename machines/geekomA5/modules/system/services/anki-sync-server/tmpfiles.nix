{
  systemd.tmpfiles.settings."90-anki-sync-server" = {
    "/mnt/store/anki-sync-server" = {
      "d" = {
        mode = "0750";
      };
    };
  };
}
