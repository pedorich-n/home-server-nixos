{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}:
let
  name = "n8n-nodes-imap";
  version = "2.15.0";
in
buildNpmPackage {
  pname = name;
  inherit version;

  src = fetchFromGitHub {
    owner = "umanamente";
    repo = name;
    rev = "v${version}";
    sha256 = "sha256-k4qjFH292hA/SgEMRYGWc0y4mijWI1dlLiqeH5OjUtg=";
  };

  # This dependency tries to install pnpm during build
  postPatch = ''
    sed -i '/"eslint-plugin-n8n-nodes-base":/d' package.json
  '';

  npmDepsHash = "sha256-w+SDm9cPVoAVpnHk/QT4efNcptLu81djvMjnQODPzu4=";
}
