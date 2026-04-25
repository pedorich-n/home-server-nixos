{
  sources,
  lib,
  stdenv,
  gettext,
  nix-update-script,
}:
stdenv.mkDerivation {
  inherit (sources.cockpit-podman) pname version src;

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
    updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
  };

  meta = {
    description = "Cockpit UI for podman containers";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
