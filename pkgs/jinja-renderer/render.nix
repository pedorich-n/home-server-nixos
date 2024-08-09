{ pkgs
, lib
, jinja-renderer
, ...
}:
{ templates
, includes ? [ ]
, variables ? { }
, outputPrefix ? ""
, name ? "templates"
, strict ? true
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "rendered-${name}";

  srcs = [
    (builtins.path { name = "templates"; path = templates; })
  ] ++ includes;

  sourceRoot = ".";

  dontConfigure = true;
  dontPatch = true;
  dontInstall = true;
  dontFixup = true;

  passAsFile = [ "variables" ];
  variables = builtins.toJSON variables;
  inherit outputPrefix;

  nativeBuildInputs = [ jinja-renderer ];

  buildPhase =
    let
      arguments = [
        ''--template "$sourceRoot/templates"''
        ''--output "$dst"''
      ]
      ++ lib.optionals (includes != [ ]) ''--include ${builtins.map (include: "$sourceRoot/$(stripHash ${include})") includes}''
      ++ lib.optional (variables != { }) ''--variables "$variablesPath"''
      ++ lib.optional strict "--strict";
    in
    ''
      runHook preBuild

      dst="$out/$outputPrefix"
      mkdir -p "$dst"
      renderer ${lib.concatStringsSep " " arguments}

      runHook postBuild
    '';
}

