import argparse
import os
import sys
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path

import holidays
import icalendar
import requests
from holidays.constants import PUBLIC, WORKDAY

CALENDARS: tuple[tuple[str, str, str, tuple[str, ...]], ...] = (
    ("Holidays in Japan", "JP", "f74b3d44-af0c-df44-39eb-a2e4dd0dded4", (PUBLIC,)),
    (
        "Holidays in Ukraine",
        "UA",
        "657d386c-1325-026a-87c8-624e9e4a3fc7",
        (PUBLIC, WORKDAY),
    ),
)

MIN_EVENTS: int = 50
YEARS: int = 3


def env_or_file(name: str) -> str | None:
    if name in os.environ:
        return os.environ[name]
    path = os.environ.get(f"{name}_FILE")
    if path is None:
        return None
    try:
        return Path(path).read_text().strip()
    except OSError as error:
        sys.exit(f"{path}: {error}")


def build(name: str, country: str, categories: tuple[str, ...], years: range) -> tuple[bytes, int]:
    calendar = icalendar.Calendar()
    calendar.add("PRODID", "-//home-server-nixos//holidays//EN")
    calendar.add("VERSION", "2.0")
    calendar.add("X-WR-CALNAME", name)

    days = holidays.country_holidays(country, years=years, categories=categories, language="en_US")
    if len(days) < MIN_EVENTS:
        raise RuntimeError(f"{name}: only {len(days)} events, refusing to upload")

    for day, holiday_name in sorted(days.items()):
        component = icalendar.Event()
        component.add("UID", f"{country}-{day:%Y%m%d}@holiday-sync")
        component.add(
            "DTSTAMP",
            datetime.combine(day, time.min, tzinfo=timezone.utc),
        )
        component.add("DTSTART", day)
        component.add("DTEND", day + timedelta(days=1))
        component.add("SUMMARY", holiday_name)
        component.add("TRANSP", "TRANSPARENT")
        calendar.add_component(component)
    return calendar.to_ical(), len(days)


def sync(
    session: requests.Session,
    base_url: str,
    user: str,
    state_dir: Path,
    name: str,
    uuid: str,
    country: str,
    categories: tuple[str, ...],
    years: range,
    dry_run: bool,
) -> bool:
    body, count = build(name, country, categories, years)
    cached = state_dir / f"{uuid}.ics"
    if cached.exists() and cached.read_bytes() == body:
        print(f"{name}: unchanged ({count} events)")
        return False

    print(f"{name}: {'would replace' if dry_run else 'replace'} ({count} events)")
    if dry_run:
        return True

    response = session.put(
        f"{base_url}/{user}/{uuid}/",
        data=body,
        headers={
            "Content-Type": "text/calendar; charset=utf-8",
            "If-Match": "*",
        },
        timeout=120,
    )
    response.raise_for_status()
    cached.write_bytes(body)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--url",
        default=env_or_file("RADICALE_URL"),
        help="Radicale base URL (env RADICALE_URL)",
    )
    parser.add_argument(
        "--user",
        default=env_or_file("RADICALE_USER"),
        help="Radicale account (env RADICALE_USER or RADICALE_USER_FILE)",
    )
    parser.add_argument("--dry-run", action="store_true", help="report actions without writing")
    args = parser.parse_args()

    password: str | None = env_or_file("RADICALE_PASSWORD")
    if password is None:
        sys.exit("RADICALE_PASSWORD or RADICALE_PASSWORD_FILE is not set")
    if args.url is None:
        sys.exit("RADICALE_URL is not set")
    if args.user is None:
        sys.exit("RADICALE_USER or RADICALE_USER_FILE is not set")

    state_value: str | None = os.environ.get("STATE_DIR") or os.environ.get("STATE_DIRECTORY")
    if state_value is None:
        sys.exit("STATE_DIR or STATE_DIRECTORY is not set")
    state_dir = Path(state_value)
    state_dir.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.auth = (args.user, password)

    years = range(date.today().year - YEARS, date.today().year + YEARS + 1)
    replaced: int = 0
    try:
        for name, country, uuid, categories in CALENDARS:
            replaced += sync(
                session,
                args.url.rstrip("/"),
                args.user,
                state_dir,
                name,
                uuid,
                country,
                categories,
                years,
                args.dry_run,
            )
    except (requests.RequestException, OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"total: {replaced} of {len(CALENDARS)} calendars replaced")
    return 0


if __name__ == "__main__":
    sys.exit(main())
