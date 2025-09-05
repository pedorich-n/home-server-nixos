{
  curl,
  jo,
  jq,
  lldap,
  makeWrapper,
  stdenvNoCC,
  lib,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "lldap-bootrstrap";
  inherit (lldap) version src;

  propagatedBuildDependencies = [
    jq
    curl
    jo
    lldap
  ];

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src/scripts/bootstrap.sh $out/bin/lldap-bootstrap

    wrapProgram $out/bin/lldap-bootstrap \
      --set LLDAP_SET_PASSWORD_PATH ${lib.getExe' lldap "lldap_set_password"} \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          jo
          jq
        ]
      }

  '';

  meta.mainPackage = "lldap-bootstrap";
}
