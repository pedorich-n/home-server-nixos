{
  writers,
}:
writers.writePython3Bin "holiday-sync" {
  libraries =
    ps:
    (with ps; [
      holidays
      icalendar
      requests
    ]);
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./holiday-sync.py)
