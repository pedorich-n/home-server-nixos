{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Hardware
    lshw
    parted

    # Utils
    rsync
  ];
}
