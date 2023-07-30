{
  networking = {
    hostName = "nucbox5"; # TODO: read from config?
    networkmanager.enable = true;
    wireless.enable = false; # Using Ethernet
    nat.enable = true;
  };
}
