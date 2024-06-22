{
  services.udev = {
    enable = true;
    # Use `udevadm info -a /dev/XXX` or `lsusb -v` to get those attrs
    extraRules = '' 
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0664", GROUP="zigbee"

      KERNEL=="nvme[0-9]", GROUP="disk"
    '';
  };
}
