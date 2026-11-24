import argparse
import os
import sys
import xml.etree.ElementTree as ET
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path

import holidays
import icalendar
import requests
from holidays.constants import PUBLIC, WORKDAY

DAV = "DAV:"
CALDAV = "urn:ietf:params:xml:ns:caldav"
COMPONENT_SET = f"{{{CALDAV}}}supported-calendar-component-set"
COMPONENTS: tuple[str, ...] = ("VEVENT",)

CALENDARS: tuple[tuple[str, str, str, tuple[str, ...]], ...] = (
    ("Holidays in Japan", "JP", "f74b3d44-af0c-df44-39eb-a2e4dd0dded4", (PUBLIC,)),
    (
        "Holidays in Ukraine",
        "UA",
        "657d386c-1325-026a-87c8-624e9e4a3fc7",
        (PUBLIC, WORKDAY),
    ),
)

PROPFIND_BODY = f"""<?xml version="1.0" encoding="utf-8"?>
<D:propfind xmlns:D="{DAV}" xmlns:C="{CALDAV}">
  <D:prop>
    <C:supported-calendar-component-set/>
  </D:prop>
</D:propfind>"""

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


def read_components(session: requests.Session, url: str) -> tuple[str, ...] | None:
    """Current supported component set, or None if the collection is missing."""
    response = session.request(
        "PROPFIND",
        url,
        data=PROPFIND_BODY,
        headers={"Depth": "0", "Content-Type": 'text/xml; charset="utf-8"'},
        timeout=60,
    )
    if response.status_code == 404:
        return None
    response.raise_for_status()

    for prop in ET.fromstring(response.content).iter(COMPONENT_SET):
        return tuple(comp.get("name", "") for comp in prop)
    return ()


def proppatch_body() -> bytes:
    components = "".join(f'<C:comp name="{name}"/>' for name in COMPONENTS)
    return f"""<?xml version="1.0" encoding="utf-8"?>
<D:propertyupdate xmlns:D="{DAV}" xmlns:C="{CALDAV}">
  <D:set>
    <D:prop>
      <C:supported-calendar-component-set>{components}</C:supported-calendar-component-set>
    </D:prop>
  </D:set>
</D:propertyupdate>""".encode()


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
    url = f"{base_url}/{user}/{uuid}/"
    cached = state_dir / f"{uuid}.ics"

    present = read_components(session, url)
    body_current = present is not None and cached.exists() and cached.read_bytes() == body
    components_current = present == COMPONENTS

    actions: list[str] = []
    if not body_current:
        actions.append(f"{'create' if present is None else 'replace'} ({count} events)")
    if not components_current:
        actions.append("update calendar type")

    if not actions:
        print(f"{name}: unchanged ({count} events)")
        return False

    print(f"{name}: {'would ' if dry_run else ''}{', '.join(actions)}")
    if dry_run:
        return True

    if not body_current:
        response = session.put(
            url,
            data=body,
            headers={
                "Content-Type": "text/calendar; charset=utf-8",
                "If-None-Match" if present is None else "If-Match": "*",
            },
            timeout=120,
        )
        response.raise_for_status()
        cached.write_bytes(body)

    response = session.request(
        "PROPPATCH",
        url,
        data=proppatch_body(),
        headers={"Content-Type": 'text/xml; charset="utf-8"'},
        timeout=60,
    )
    response.raise_for_status()
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
    updated: int = 0
    try:
        for name, country, uuid, categories in CALENDARS:
            updated += sync(
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
    except (requests.RequestException, OSError, RuntimeError, ValueError, ET.ParseError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"total: {updated} of {len(CALENDARS)} calendars updated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
