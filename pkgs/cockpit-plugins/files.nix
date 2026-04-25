{
  lib,
  stdenv,
  fetchurl,
  gettext,
  python3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-files";
  version = "39";
  src = fetchurl {
    url = "https://github.com/cockpit-project/cockpit-files/releases/download/${finalAttrs.version}/cockpit-files-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-2YpDSqWy83/eZ39T0ICqqzJyzJIbBlQbQQdWQdT9ebM=";
  };

  nativeBuildInputs = [
    gettext
  ];

  buildInputs = [
    python3
  ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
  ];

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
    maintainers = [ ];
  };
})
