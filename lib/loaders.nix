{ haumea, lib, ... }:
let
  /* 
    Given an attrset, takes all the values recursivelly and joins them into a single list.
  
    For example, for attrset like 
    ```nix
    {
      users = {
        root = {
          home = ./users/root/home.nix;
        };
        user = {
          home = ./users/user/home.nix;
        };
      };
    };
    ```

    The output will be
    ```nix
      [ ./users/root/home.nix ./users/user/home.nix ]
    ```
  */
  foldAttrValuesToListRecursive = attrset:
    lib.foldl'
      (acc: value:
        if (lib.isPath value || lib.isString value || lib.isDerivation value) then
          acc ++ [ value ]
        else if (lib.isAttrs value) then
          acc ++ (foldAttrValuesToListRecursive value)
        else
          lib.trace value (builtins.abort "Unknown type of value!")
      )
      [ ]
      (builtins.attrValues attrset);

  /* 

    Reads nested directory structure and outputs a flat list of all nix files excluding ones that start with underscore.

    For directory structure 

      users
      ├── root
      │   └── home.nix
      └── user
        └── home.nix

    The output will be
    ```nix
      [ ./users/root/home.nix ./users/user/home.nix ]
    ```
   */
  listModules = { src }:
    foldAttrValuesToListRecursive (haumea.lib.load {
      inherit src;
      loader = haumea.lib.loaders.path;
    });

  /* 
    Loads directory structure into attrset where name is the top level folder and value is the list of nix files inside. 
    For directory structure 

      users
      ├── root
      │   └── home.nix
      └── user
        └── home.nix
  
    The output will be 
    ```nix
    {
      root = [ ./users/root/home.nix ];
      user = [ ./users/user/home.nix ];
    }
    ```
  */
  listNamedSubmodules = { src }:
    let
      topLevelModules = haumea.lib.load {
        inherit src;
        loader = haumea.lib.loaders.path;
      };
    in
    builtins.mapAttrs (module: _: listModules { src = "${src}/${module}"; }) topLevelModules;

in
{
  inherit listModules listNamedSubmodules;
}
