{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "systemd-onfailure-notify";
  runtimeInputs = [
    pkgs.apprise
    pkgs.ripgrep
    pkgs.systemd
  ];
  text = ''
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --apprise-config)
                APPRISE_CONFIG="''${2}"
                shift 2
                ;;
            --unit)
                UNIT_NAME="''${2}"
                shift 2
                ;;
            --lines)
                LINES_COUNT="''${2:}"
                shift 2
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    if [[ -z "''${APPRISE_CONFIG}" || -z "''${UNIT_NAME}" ]]; then
        echo "--apprise-config and --unit are required"
        exit 1
    fi

    LINES_COUNT="''${LINES_COUNT:-500}"

    BASE_PATH_LOGS="/tmp/systemd_notifications"

    STATUS=$(systemctl status "''${UNIT_NAME}" --no-pager | rg --only-matching "Active:\s(?P<status>.+)" --replace '$status')

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
