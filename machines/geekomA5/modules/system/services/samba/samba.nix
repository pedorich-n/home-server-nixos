{
  custom.networking.ports = {
    tcp = {
      samba-session-service = { port = 139; openFirewall = true; };
      samba = { port = 445; openFirewall = true; };
      samba-wsdd = { port = 5357; openFirewall = true; };
    };

    udp = {
      samba-name-service = { port = 138; openFirewall = true; };
      samba-datagram-service = { port = 139; openFirewall = true; };
      samba-wsdd = { port = 3702; openFirewall = true; };
    };
  };

  services = {
    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "netbios name" = "Server";
          "map to guest" = "Bad User";
        };
        public = {
          "comment" = "Server Public";
          "path" = "/mnt/external/data-library/share/public";
          "public" = "yes";
          "browseable" = "yes";
          "writable" = "yes";
          "guest ok" = "yes";
          "guest only" = "yes";
          "create mask" = "0644";
          "directory mask" = "0777";
        };
      };
    };

    samba-wsdd = {
      # This enables autodiscovery on Windows
      enable = true;
    };
  };
}
