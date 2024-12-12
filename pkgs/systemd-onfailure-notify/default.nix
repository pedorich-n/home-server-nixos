{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "systemd-onfailure-notify";
  runtimeInputs = [
    pkgs.apprise
    pkgs.getopt
    pkgs.ripgrep
    pkgs.systemd
  ];
  text = ''
    TEMP=$(getopt -o "" -l apprise-config:,unit:,lines: -- "$@") || exit 1
    eval set -- "$TEMP"

    APPRISE_CONFIG=""
    UNIT_NAME=""
    LINES_COUNT=500

    while [[ "$1" != "--" ]]; do
        case "$1" in
            --apprise-config) APPRISE_CONFIG="$2"; shift 2 ;;
            --unit) UNIT_NAME="$2"; shift 2 ;;
            --lines) LINES_COUNT="$2"; shift 2 ;;
        esac
    done
    shift # Skip the "--"

    [[ -z "$APPRISE_CONFIG" || -z "$UNIT_NAME" ]] && {
        echo "--apprise-config and --unit are required" >&2
        exit 1
    }

    BASE_PATH_LOGS="/tmp/systemd_notifications"

    STATUS=$(systemctl status "''${UNIT_NAME}" --no-pager 2>&1 | rg --only-matching "Active:\s(?P<status>.+)" --replace '$status') || echo "''${STATUS}"

    mkdir -p "''${BASE_PATH_LOGS}"

    NOW=$(date +'%Y-%m-%dT%H-%M-%S')
    LOGS_FILENAME="''${BASE_PATH_LOGS}/''${UNIT_NAME}_''${NOW}.log"
    LOGS=$(journalctl --boot --no-pager --output short-iso --no-hostname --unit "''${UNIT_NAME}" --lines "''${LINES_COUNT}")

    echo "''${LOGS}" > "''${LOGS_FILENAME}"

    MESSAGE_BODY=$(cat <<EOF
    Service **''${UNIT_NAME}** failed!

    **Status**: ''${STATUS}
    EOF
    )

    # shellcheck disable=SC2064
    trap "rm -f ''${LOGS_FILENAME}" EXIT

    apprise --config="''${APPRISE_CONFIG}" --input-format="markdown" --body="''${MESSAGE_BODY}" --attach="''${LOGS_FILENAME}"
  '';
}
