{ config, ... }: {
  services.udev = {
    enable = true;
    # Use `udevadm info -a /dev/XXX` or `lsusb -v` to get those attrs
    extraRules = '' 
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0664", GROUP="${config.users.groups.zigbee.name}"
    '';
  };
}
