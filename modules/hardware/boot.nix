{
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
    };
    kernel = {
      sysctl = {
        "net.ipv4.ip_unprivileged_port_start" = 52; # allow binding to ports >=53 instead of >=1024, for rootless podman 
      };
    };
    kernelModules = [ "kvm-intel" ];

    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
        configurationLimit = 5;
      };
    };
  };
}
