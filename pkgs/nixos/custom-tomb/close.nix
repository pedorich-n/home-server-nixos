{
  writeShellApplication,
  cryptsetup,
  util-linux,
}:
writeShellApplication {
  name = "tomb-close";
  runtimeInputs = [
    cryptsetup
    util-linux
  ];
  text = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 <mount_point> [mapper_name]" >&2
      exit 1
    fi

    MOUNT_POINT="$1"
    MAPPER_NAME="''${2:-tomb}"

    if [ "$EUID" -ne 0 ]; then
      echo "Error: This script must be run with sudo." >&2
      exit 1
    fi

    if mountpoint -q "$MOUNT_POINT"; then
      umount "$MOUNT_POINT"
    fi

    if [ -e "/dev/mapper/$MAPPER_NAME" ]; then
      cryptsetup close "$MAPPER_NAME"
    fi

    echo "Success: Tomb securely closed."
  '';
}
