{
  lib,
  ...
}:
{
  flake.lib.tools = {
    # Adapted from https://github.com/divnix/digga/blob/117be8023d7615f16/src/importers.nix#L2-L59
    flattenDerivationsTree = {
      __functor =
        _self: tree:
        let
          op =
            sum: path: val:
            let
              pathStr = builtins.concatStringsSep "." path; # dot-based reverse DNS notation
            in
            if lib.isDerivation val then # Original was `builtins.isPath`
              # builtins.trace "${toString val} is a derivation"
              (sum // { "${pathStr}" = val; })
            else if builtins.isAttrs val then
              # builtins.trace "${builtins.toJSON val} is an attrset"
              # recurse into that attribute set
              (recurse sum path val)
            else
              # ignore that value
              # builtins.trace "${toString path} is something else"
              sum;

          recurse =
            sum: path: val:
            builtins.foldl' (sum: key: op sum (path ++ [ key ]) val.${key}) sum (builtins.attrNames val);
        in
        recurse { } [ ] tree;

      doc = ''
        Synopsis: flattenDerivationsTree _tree_

        Flattens a _tree_ of the shape that is produced by `lib.filesystem.packagesFromDirectoryRecursive`.

        Output Format:
        An attrset with names in the spirit of the Reverse DNS Notation form
        that fully preserve information about grouping from nesting.

        Example input:
        ```
        {
          a = {
            b = {
              c = <drv>;
            };
          };
        }
        ```

        Example output:
        ```
        {
          "a.b.c" = <drv>;
        }
        ```
        *
      '';
    };
  };
}
