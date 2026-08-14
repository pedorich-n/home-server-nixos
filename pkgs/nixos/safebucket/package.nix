{
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
buildGoModule (finalAttrs: {
  pname = "safebucket";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "safebucket";
    repo = "safebucket";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3If5AB11XjDZTTKo3fD/7tL2B8mJ1WPLjs99D6VgDic=";
  };

  vendorHash = "sha256-ECt253rRthcknYx2RQ+U9pyRbuGG0kIzHlrdUyxeK3k=";

  strictDeps = true;
  __structuredAttrs = true;

  env.CGO_ENABLED = 1;

  ldflags = [
    "-s"
    "-w"
  ];

  preBuild = ''
    mkdir -p web/dist
    cp -r ${finalAttrs.passthru.frontend}/. web/dist
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--flake"
        "--subpackage"
        "frontend"
      ];
    };

    frontend = buildNpmPackage {
      pname = "safebucket-frontend";
      inherit (finalAttrs) src version;

      strictDeps = true;
      __structuredAttrs = true;

      sourceRoot = "${finalAttrs.src.name}/web";

      npmDepsHash = "sha256-289QPGVgf9W5fZztdC/9zxlV/L6uX607AbpldBnaSj0=";

      installPhase = ''
        runHook preInstall

        mkdir $out
        cp -r dist/. $out

        runHook postInstall
      '';
    };
  };

  meta = {
    mainProgram = "safebucket";
    description = "On-prem file sharing made simple, fast and safe.";
    homepage = "https://github.com/safebucket/safebucket";
    changelog = "https://github.com/safebucket/safebucket/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
