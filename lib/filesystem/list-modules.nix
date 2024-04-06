# TODO: better name
{ haumea, lib }:
let
  foldAttrValuesToListRecursive = attrset:
    lib.concatLists (lib.mapAttrsToList
      (_: value:
        if builtins.isAttrs value then foldAttrValuesToListRecursive value else [ value ]
      )
      attrset);
in
{ src
}:
foldAttrValuesToListRecursive (haumea.lib.load {
  inherit src;
  loader = haumea.lib.loaders.path;
})
