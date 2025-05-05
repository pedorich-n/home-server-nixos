{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "generate-host-keys";
  runtimeInputs = with pkgs; [
    coreutils
    openssh
  ];
  text = ''
    function generate_key() {
      root=$1
      type=$2
      path="''${root}/ssh_host_''${type}_key"

      # Create new SSH key of a given type, with no passphrase, and no comment; save to the temporary directory
      ssh-keygen -t "''${type}" \
        -N "" \
        -C "" \
        -f "''${path}"

      # Set the correct permissions so sshd will accept the key
      chmod 600 "''${path}"

      echo "Generated key ''${path}"
    }

    # Create a temporary directory
    temp=$(mktemp -d)

    types=("ed25519" "rsa")
    roots=("''${temp}/etc/ssh" "''${temp}/etc/initrd/ssh")

    for type in "''${types[@]}"; do
      for root in "''${roots[@]}"; do
        # Create the directory where sshd expects to find the host keys  
        install -d -m755 "''${root}"

        generate_key "''${root}" "''${type}"

      done
    done        

    echo ""
    echo "Pass '--extra-files ''${temp}' to nixos-anywhere"
    echo ""
    echo "Don't forget to 'rm -r ''${temp}' after deploying with nixos-anywhere!"
  '';
}
