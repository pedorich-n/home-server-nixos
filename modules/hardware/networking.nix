{
  networking = {
    hostName = "nucbox5";
    networkmanager.enable = true;
    wireless.enable = false; # Using Ethernet
    nat.enable = true;
  };
}
