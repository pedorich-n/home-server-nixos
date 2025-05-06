{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "convert-host-keys";
  runtimeInputs = with pkgs; [
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
