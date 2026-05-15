{
  sources,
  lib,
  buildGoModule,
}:
buildGoModule (finalAttrs: {
  inherit (sources.error-pages) pname src;
  version = lib.removePrefix "v" sources.error-pages.version;
  vendorHash = null;

  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X gh.tarampamp.am/error-pages/v4/internal/appmeta.version=${finalAttrs.version}"
  ];

  subPackages = [
    "cmd/builder"
    "cmd/error-pages"
  ];

  postBuild = ''
    static_target=$out/share/error-pages
    mkdir -p $static_target

    "''${GOPATH}/bin/builder" --index --target-dir $static_target
  '';

  meta = {
    description = "Static error pages generator for HTTP servers";
    homepage = "https://tarampampam.github.io/error-pages";
    license = lib.licenses.mit;
    mainProgram = "error-pages";
  };
})
