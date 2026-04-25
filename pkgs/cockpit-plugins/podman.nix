{
  lib,
  fetchurl,
  stdenv,
  gettext,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-podman";
  version = "124";
  src = fetchurl {
    url = "https://github.com/cockpit-project/cockpit-podman/releases/download/${finalAttrs.version}/cockpit-podman-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-g93+OH2YPF/b/llXz00DM7JiyfWpWYXEHAbgLoM6Fbo=";
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

  meta = {
    description = "Cockpit UI for podman containers";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
