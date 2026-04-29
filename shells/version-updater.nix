{
  mkShellNoCC,
  nvchecker,
  nvfetcher,
  ...
}:
mkShellNoCC {
  name = "version-updater";

  packages = [
    nvchecker
    nvfetcher
  ];
}
