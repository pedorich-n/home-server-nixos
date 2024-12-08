{ lib
, stdenv
, fetchzip
, gettext
,
}:
stdenv.mkDerivation rec {
  pname = "cockpit-podman";
  version = "99";

  src = fetchzip {
    sha256 = "140sjw0pmzxs2hm33hrrragyhqq5gfp7n5ypma4bm6mnnnx0dydd";
    url = "https://github.com/cockpit-project/cockpit-podman/releases/download/${version}/cockpit-podman-${version}.tar.xz";
  };

  nativeBuildInputs = [ gettext ];

  makeFlags = [ "DESTDIR=$(out)" "PREFIX=" ];

  # postPatch = ''
  #   substituteInPlace Makefile \
  #     --replace /usr/share $out/share
  #   touch pkg/lib/cockpit-po-plugin.js
  #   touch dist/manifest.json
  # '';

  dontBuild = true;

  meta = {
    description = "Cockpit UI for podman containers";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
