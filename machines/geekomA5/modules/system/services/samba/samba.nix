{ pkgs, ... }:
{
  custom.networking.ports = {
    tcp = {
      samba-session-service = { port = 139; openFirewall = true; };
      samba = { port = 445; openFirewall = true; };
      samba-wsdd = { port = 5357; openFirewall = true; };
    };

    udp = {
      avahi-mdns = { port = 5353; openFirewall = true; };
      samba-name-service = { port = 138; openFirewall = true; };
      samba-datagram-service = { port = 139; openFirewall = true; };
      samba-wsdd = { port = 3702; openFirewall = true; };
    };
  };

  services = {
    samba = {
      enable = true;
      package = pkgs.samba4Full;
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

    avahi = {
      # This _should_ enable auto-discovery via mDNS. In reality it depends on the devices in the network :(
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
