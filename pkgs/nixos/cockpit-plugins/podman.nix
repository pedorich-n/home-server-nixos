{
  lib,
  fetchurl,
  stdenv,
  gettext,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-podman";
  version = "125";
  src = fetchurl {
    url = "https://github.com/cockpit-project/cockpit-podman/releases/download/${finalAttrs.version}/cockpit-podman-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-6XathPDmpJ4g3zn0pKoagsDNBQ+9o3iPd2nVs615esw=";
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
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Cockpit UI for podman containers";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
