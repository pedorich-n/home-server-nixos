{
  writers,
}:
writers.writePython3Bin "forgejo-mirror-seeder" {
  libraries =
    ps:
    (with ps; [
      requests
    ]);
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./seeder.py)
