{
  fetchzip,
  stdenv,
  lib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "error-pages";
  version = "4.2.2";

  src = fetchzip {
    url = "https://github.com/tarampampam/error-pages/releases/download/v${finalAttrs.version}/error-pages-static.zip";
    hash = "sha256-hbXI2DLQlQt4IEjb49YlgGudfcr5+OJauwurL/5lnZ8=";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/error-pages
    cp -r $src/* $out/share/error-pages

    runHook postInstall
  '';

  passthru = {
    useNixUpdate = true;
  };

  meta = {
    description = "Static error pages for HTTP servers";
    homepage = "https://tarampampam.github.io/error-pages";
    license = lib.licenses.mit;
  };
})
