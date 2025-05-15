{ lib, stdenv, fetchzip, gettext, python3 }:
stdenv.mkDerivation rec {
  pname = "cockpit-files";
  version = "20";

  src = fetchzip {
    sha256 = "sha256-aQVqo9lq7dVoQeTUd56fAxEc9wP0LCx2ZqAH4n7AQ84=";
    url = "https://github.com/cockpit-project/cockpit-files/releases/download/${version}/cockpit-files-${version}.tar.xz";
  };

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
