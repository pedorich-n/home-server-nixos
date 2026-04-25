{
  lib,
  stdenv,
  fetchurl,
  gettext,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-files";
  version = "40";
  src = fetchurl {
    url = "https://github.com/cockpit-project/cockpit-files/releases/download/${finalAttrs.version}/cockpit-files-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-Yp6s9x0Vu8Lgcg71aImTLJ8YNKJkfxhbSOcPckJVAGI=";
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

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Cockpit UI for local files";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-files";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
