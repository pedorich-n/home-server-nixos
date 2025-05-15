{ lib
, stdenv
, callPackage
, gettext
, python3
}:
let
  sources = callPackage ./_sources/generated.nix { };
in
stdenv.mkDerivation {
  inherit (sources.cockpit-files) pname version src;

  nativeBuildInputs = [
    gettext
  ];

  buildInputs = [
    python3
  ];

  makeFlags = [ "DESTDIR=$(out)" "PREFIX=" ];

  postFixup = ''
    gunzip $out/share/cockpit/files/index.js.gz

    substituteInPlace $out/share/cockpit/files/index.js \
      --replace-fail '/usr/bin/python3' '${python3.interpreter}'

    gzip -9 $out/share/cockpit/files/index.js
  '';

  dontBuild = true;

  meta = {
    description = "Cockpit UI for local files";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-files";
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ ];
  };
}
