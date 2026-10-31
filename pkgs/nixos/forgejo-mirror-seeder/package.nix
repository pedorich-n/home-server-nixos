{
  python3Packages,
  writers,
}:
writers.writePython3Bin "forgejo-mirror-seeder" {
  libraries = [ python3Packages.requests ];
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./seeder.py)
