{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustic-exporter";
  version = "0.1.0-rc.11";

  src = fetchFromGitHub {
    owner = "timtorChen";
    repo = "rustic-exporter";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-7skCaOPD4JYEut3wp34Myo9IWXutlp4FEqUZPxwi2j8=";
  };

  cargoHash = "sha256-h9gM9FIwz7xWwMyB5OVsU2dARySpJ7FCg9rjppNgBzg=";

  meta = with lib; {
    mainProgram = "rustic-exporter";
    description = "Prometheus exporter for rustic/restic backup";
    homepage = "https://github.com/timtorChen/rustic-exporter";
    changelog = "https://github.com/timtorChen/rustic-exporter/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };

})
