{
  flake,
  lib,
  ...
}:
{
  flake.overlays =
    let
      overlayFiles = flake.lib.loaders.listFilesRecursively {
        src = ../overlays;
      };

      overlays = lib.map (path: import path) overlayFiles;
    in
    {
      default = lib.composeManyExtensions overlays;
    };
}
