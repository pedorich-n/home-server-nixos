{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "generate-host-key";
  runtimeInputs = with pkgs; [ coreutils openssh ];
  text = ''
    # Create a temporary directory
    temp=$(mktemp -d)
    type="ed25519"
    path="''${temp}/etc/ssh/ssh_host_''${type}_key"

    # Create the directory where sshd expects to find the host keys
    install -d -m755 "''${temp}/etc/ssh"

    # Create new SSH key of a given type, with no passphrase, and save to the temporary directory
    # No passphrase
    # No comment (by default it's generated using <username>@<hostname>)
    ssh-keygen -t "''${type}" \
      -N "" \
      -C "" \
      -f "''${path}"

    # Set the correct permissions so sshd will accept the key
    chmod 600 "''${path}"


    echo ""
    echo "Pass '--extra-files ''${temp}' to nixos-anywhere"
    echo ""
    echo "Your public key is"
    cat "''${path}.pub"
    echo ""
    echo "Don't forget to 'rm -r ''${temp}' after deploying with nixos-anywhere!"
  '';
}
