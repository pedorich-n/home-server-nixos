{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    tomb # encrypted storage management tool
    rustic-exporter # Restic metrics exporter for Prometheus
  ];
}
