{
  writeShellApplication,
  fd,
  openssh,
  ssh-to-age,
}:
writeShellApplication {
  name = "convert-host-keys";
  meta.description = "Convert OpenSSH public keys to age format, for use with sops";
  runtimeInputs = [
    fd
    openssh
    ssh-to-age
  ];
  text = ''
    root=$1

    function convert() {
      publicKeyPath=$1
      echo ""
      ssh-keygen -l -f "''${publicKeyPath}"
      ssh-to-age -i "''${publicKeyPath}"
    }
    export -f convert

    fd --absolute-path --base-directory "''${root}" --type file --extension pub --exec bash -c "convert {}"
  '';
}
