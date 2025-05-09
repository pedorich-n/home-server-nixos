{ config, lib, pkgs, ... }:
{
  boot.initrd = {
    supportedFilesystems = {
      ext4 = lib.mkDefault true;
    };

    # https://gist.github.com/CMCDragonkai/810f78ee29c8fce916d072875f7e1751
    availableKernelModules = [
      # Storage
      "ahci" # SATA devices on modern AHCI controllers
      "sd_mod" # SCSI, SATA, and PATA (IDE) devices
      "nvme" # NVME Drives

      "xhci_pci" # USB 3.0 (eXtensible Host Controller Interface)
      "ehci_pci" # USB 2.0 (Enhanced Host Controller Interface)
    ];

    systemd = {
      network.enable = lib.mkIf config.boot.initrd.systemd.enable (lib.mkOverride 950 true);

      initrdBin = with pkgs; [
        bashInteractive
        curlMinimal
        dig
      ];
    };

    services.resolved = {
      enable = lib.mkIf config.boot.initrd.systemd.enable (lib.mkOverride 950 true);
    };

    network.ssh = lib.mkMerge [
      {
        enable = lib.mkDefault true;
        port = lib.mkDefault 2222; # To avoid ssh client complaining about different Host Key
        shell = lib.mkDefault "/bin/bash";
      }
      (lib.mkIf (config ? custom.ssh.keys) {
        authorizedKeys = lib.mkDefault config.custom.ssh.keys;
      })
    ];
  };
}
