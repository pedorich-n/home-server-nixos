{
  writeShellApplication,
  gnupg,
  cryptsetup,
  util-linux,
}:
writeShellApplication {
  name = "tomb-open";
  runtimeInputs = [
    cryptsetup
    util-linux
    gnupg
  ];

  text = ''
    if [ "$#" -lt 3 ]; then
      echo "Usage: $0 <tomb_file> <key_file> <mount_point> [mapper_name]" >&2
      exit 1
    fi

    TOMB_FILE="$1"
    KEY_FILE="$2"
    MOUNT_POINT="$3"
    MAPPER_NAME="''${4:-tomb}"

    if [ "$EUID" -ne 0 ]; then
      echo "Error: This script must be run with sudo." >&2
      exit 1
    fi

    if [ ! -f "$TOMB_FILE" ]; then
      echo "Error: Tomb file does not exist at $TOMB_FILE" >&2
      exit 1
    fi
    if [ ! -f "$KEY_FILE" ]; then
      echo "Error: Key file does not exist at $KEY_FILE" >&2
      exit 1
    fi
    if [ -z "$TOMB_KEY_PASS" ]; then
      echo "Error: TOMB_KEY_PASS environment variable is not set." >&2
      exit 1
    fi

    if mountpoint -q "$MOUNT_POINT"; then
      echo "Success: Tomb is already mounted at $MOUNT_POINT"
      exit 0
    fi

    mkdir -p "$MOUNT_POINT"

    if [ ! -e "/dev/mapper/$MAPPER_NAME" ]; then
      echo -n "$TOMB_KEY_PASS" | gpg --quiet --batch --passphrase-fd 0 --decrypt "$KEY_FILE" | \
        cryptsetup open --type luks "$TOMB_FILE" "$MAPPER_NAME" --key-file -
    fi

    mount /dev/mapper/"$MAPPER_NAME" "$MOUNT_POINT"

    echo "Success: Tomb mounted at $MOUNT_POINT"
  '';
}
