{
  fetchurl,
  stdenv,
  gettext,
  lib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-podman";
  version = "126";
  src = fetchurl {
    url = "https://github.com/cockpit-project/cockpit-podman/releases/download/${finalAttrs.version}/cockpit-podman-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-O4NS29ViLesIml9YGfcraqPhtT6nafOgdU0fR9djpNw=";
  };

  nativeBuildInputs = [
    gettext
  ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  dontBuild = true;

  postFixup = ''
    substituteInPlace $out/share/cockpit/podman/manifest.json \
      --replace-warn "/lib/systemd/system/podman.socket" "/run/podman/podman.sock"
  '';

  passthru = {
    useNixUpdate = true;
  };

  meta = {
    description = "Cockpit UI for podman containers";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };

})
