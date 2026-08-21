{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    tomb # encrypted storage management tool
  ];
}
