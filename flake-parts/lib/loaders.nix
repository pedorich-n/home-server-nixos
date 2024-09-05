{ lib, ... }:
let
  /* 
    Poor man's Haumea
  */
  matchers = rec {
    nix = { path, ... }: lib.hasSuffix ".nix" (builtins.toString path);

    notIgnored = { root, path, ... }:
      let
        relative = lib.removePrefix "${builtins.toString root}/" (builtins.toString path);
        parts = lib.splitString "/" relative;
        beginsWithUnderscore = part: lib.hasPrefix "_" part;
      in
      lib.all (part: !(beginsWithUnderscore part)) parts;

    default = { path, root }: (nix { inherit path; }) && (notIgnored { inherit root path; });
  };

  listFilesRecursivelly = { src, matcher ? matchers.default }:
    lib.filter (path: matcher { inherit path; root = src; }) (lib.filesystem.listFilesRecursive src);

in
{
  flake.lib.loaders = {
    inherit listFilesRecursivelly;
  };
}
