{ config, ... }:
{
  boot = {
    # See https://gist.github.com/CMCDragonkai/810f78ee29c8fce916d072875f7e1751

    initrd = {
      availableKernelModules = [
        "ahci" # SATA devices on modern AHCI controllers
        "sd_mod" # SCSI, SATA, and PATA (IDE) devices
        "nvme" # NVME Drives
        "sdhci_pci" # SD Card

        "usbcore" # USB modules (USB 2.0, USB 3.0, USB HID, etc)
      ];
    };

    kernelModules = [
      "kvm-amd" # KVM on AMD Cpus
      "k10temp" # Temperature monitoring on AMD CPUs
      "zenpower" # AMD ZEN Family CPUs current, voltage, power monitoring
    ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];

    loader.systemd-boot.enable = true;
  };
}
