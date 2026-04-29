{
  fd,
  gitMinimal,
  nvfetcher,
  writeShellApplication,
}:
writeShellApplication {
  name = "update-nvfetcher";

  runtimeInputs = [
    fd
    gitMinimal
    nvfetcher
  ];

  text = ''
    ROOT="$(git rev-parse --show-toplevel)"

    fd 'nvfetcher.toml' "$ROOT" --exec nvfetcher --config {} --build-dir "{//}/_sources" --verbose
  '';
}
