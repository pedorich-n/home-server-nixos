{
  findutils,
  gitMinimal,
  nvfetcher,
  writeShellApplication,
}:
writeShellApplication {
  name = "update-nvfetcher";

  runtimeInputs = [
    findutils
    gitMinimal
    nvfetcher
  ];

  text = ''
    ROOT="$(git rev-parse --show-toplevel)"

    find "$ROOT" -type f -name 'nvfetcher.toml' -execdir nvfetcher --config '{}' \;
  '';
}
