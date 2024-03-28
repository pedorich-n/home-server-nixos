import argparse
import logging
import subprocess
import tempfile
from pathlib import Path

import apprise

logging.basicConfig(
    level=logging.DEBUG,
    format="[{asctime}] [{levelname:<5s}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)

logger = logging.getLogger(__name__)


def get_journal(unit_name: str, lines: int) -> str:
    cmd = ["journalctl", "--boot", "--no-pager", "--output", "short-iso", "--no-hostname", "--unit", unit_name, "--lines", str(lines)]
    process_result = subprocess.run(cmd, stdout=subprocess.PIPE)
    result = process_result.stdout.decode()
    print(result)

    return result


def send_notification(config_path: Path, unit_name: str, attachement_path: Path) -> None:
    print("Sending notification")
    appobj = apprise.Apprise()
    config = apprise.AppriseConfig()

    config.add(str(config_path))
    appobj.add(config)

    # TODO: get status?
    attachment = apprise.AppriseAttachment(str(attachement_path))
    # appobj.notify(body=f"Service **{unit_name}** failed!", body_format=apprise.NotifyFormat.MARKDOWN, attach=attachment)
    appobj.notify(body=f"Service **{unit_name}** failed!", attach=str(attachement_path))


def main():
    parser = argparse.ArgumentParser(formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, max_help_position=60))
    parser.add_argument("--apprise-config", required=True, type=str, help="Path to apprise config file")
    parser.add_argument("--unit", "-u", required=True, type=str, help="Systemd unit name that failed")
    parser.add_argument("--lines", "-n", required=False, type=int, default=500, help="Number of lines to get from journalctl")

    args = parser.parse_args()
    unit = args.unit
    logger.info(f"Started notification process for {unit}")

    journal = get_journal(unit, args.lines)
    logger.info(f"Got journalctl logs for {unit}")

    temp = tempfile.NamedTemporaryFile(mode="+w", delete=False, suffix=".log", prefix=f"{unit}_")
    temp.write(journal)

    send_notification(args.apprise_config, unit, Path(temp.name))
