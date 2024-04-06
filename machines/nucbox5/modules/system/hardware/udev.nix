{
  services.udev = {
    enable = true;
    extraRules = '' 
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0664", GROUP="zigbee"
    '';
  };
}
