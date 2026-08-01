{
  fetchzip,
  stdenv,
  lib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "error-pages";
  version = "4.2.4";

  src = fetchzip {
    url = "https://github.com/tarampampam/error-pages/releases/download/v${finalAttrs.version}/error-pages-static.zip";
    hash = "sha256-Il2DSxlu/fsmAm1e2huCwHZXH92EKXUHQj9TjQVWfwo=";
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
