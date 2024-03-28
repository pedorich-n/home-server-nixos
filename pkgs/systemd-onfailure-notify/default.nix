{ poetry2nix, systemd, lib }:
poetry2nix.mkPoetryApplication {
  projectDir = ./..;
  meta.mainProgram = "systemd-onfailure-notify";

  propagatedBuildInputs = [ systemd ];
  preFixup = ''
    makeWrapperArgs+=(
      --suffix PATH : ${lib.makeBinPath [ systemd ]} 
    )
  '';
}
