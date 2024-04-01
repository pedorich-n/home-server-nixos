import argparse
import logging
import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional

import apprise

logging.basicConfig(
    level=logging.INFO,
    format="[{asctime}] [{levelname:<5s}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)

logger = logging.getLogger(__name__)


def get_journal(unit_name: str, lines: int) -> str:
    cmd = ["journalctl", "--boot", "--no-pager", "--output", "short-iso", "--no-hostname", "--unit", unit_name, "--lines", str(lines)]
    process_result = subprocess.run(cmd, stdout=subprocess.PIPE)
    result = process_result.stdout.decode()

    return result


def write_log_to_tmp(unit_name: str, content: str) -> Path:
    now = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
    file_path = Path("/tmp/systemd_notifications").joinpath(f"{unit_name}_{now}.log")
    file_path.parent.mkdir(parents=True, exist_ok=True)

    with open(file_path, "w") as file:
        file.write(content)
        file.flush()
        file.close()

    return file_path


def get_status(unit_name: str) -> Optional[str]:
    cmd = ["systemctl", "status", "--no-pager", unit_name]
    status_regex = re.compile(r"Active:\s(?P<status>.*)")
    process_result = subprocess.run(cmd, stdout=subprocess.PIPE)
    lines = process_result.stdout.decode().split("\n")

    for line in lines:
        maybe_match = status_regex.search(line)
        if maybe_match:
            status = maybe_match.group("status")
            return status

    return None


def send_notification(config_path: Path, unit_name: str, maybe_status: Optional[str], attachment_path: Path) -> None:
    logger.info("Sending notification")
    appobj = apprise.Apprise()
    config = apprise.AppriseConfig()

    config.add(str(config_path))
    appobj.add(config)

    attachment = apprise.AppriseAttachment(str(attachment_path))
    if maybe_status:
        body = f"Service **{unit_name}** failed!\n\n**Status**: {maybe_status}"
    else:
        body = f"Service **{unit_name}** failed!"

    appobj.notify(body=body, body_format=apprise.NotifyFormat.MARKDOWN, attach=attachment)


def main():
    parser = argparse.ArgumentParser(formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, max_help_position=60))
    parser.add_argument("--apprise-config", required=True, type=str, help="Path to apprise config file")
    parser.add_argument("--unit", "-u", required=True, type=str, help="Systemd unit name that failed")
    parser.add_argument("--lines", "-n", required=False, type=int, default=500, help="Number of lines to get from journalctl")

    args = parser.parse_args()
    unit = args.unit
    logger.info(f"Started notification process for {unit}")

    maybe_status = get_status(unit)
    journal = get_journal(unit, args.lines)
    logger.info(f"Got journalctl logs for {unit}")

    log_path = write_log_to_tmp(unit, journal)

    try:
        send_notification(args.apprise_config, unit, maybe_status, log_path)
    except Exception as e:
        logger.error(f"Failed to send notification for {unit}!", exc_info=e)
    finally:
        log_path.unlink(missing_ok=True)
