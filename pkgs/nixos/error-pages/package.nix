{
  fetchFromGitHub,
  buildGoModule,
  lib,
}:
buildGoModule (finalAttrs: {
  pname = "error-pages";
  version = "4.2.2";

  src = fetchFromGitHub {
    owner = "tarampampam";
    repo = "error-pages";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-08PwlzE4sYUZuIBPTYN9HTaD1h7RiQTSZvoDHWYqpj0=";
  };

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

  passthru = {
    useNixUpdate = true;
  };

  meta = {
    description = "Static error pages generator for HTTP servers";
    homepage = "https://tarampampam.github.io/error-pages";
    license = lib.licenses.mit;
    mainProgram = "error-pages";
  };
})
