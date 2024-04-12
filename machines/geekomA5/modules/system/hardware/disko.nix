{
  # FS type are from `sgdisk -L`
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 100;
              size = "512M";
              type = "EF00"; # EFI System
              label = "boot";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            root = {
              priority = 200;
              size = "150G";
              type = "8300"; # Linux filesystem
              label = "nixos";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };

            store = {
              priority = 300;
              size = "100%"; # Whatever left
              type = "8300"; # Linux filesystem
              label = "store";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/store";
              };
            };
          };
        };
      };
    };
  };
}
