"""Reconcile Forgejo pull mirrors from a declarative JSON manifest.

The manifest is an array of objects:

    [
      {
        "source": "acme/widgets",
        "owner": "backups",
        "name": "widgets",
        "private": true,
        "interval": "8h"
      }
    ]

``source`` is a GitHub ``owner/repo``. ``owner`` and ``name`` describe the
Forgejo destination. ``private`` defaults to true and ``interval`` to ``8h``.
A missing ``name`` defaults to the source repository name.

Existing mirrors are left untouched. This command only creates missing pull
mirrors; Forgejo validates the interval when the mirror is created.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import quote

import requests

LOGGER = logging.getLogger("forgejo-mirror-seeder")

DEFAULT_INTERVAL = "8h"
DEFAULT_TIMEOUT = 30.0
DEFAULT_MIGRATE_TIMEOUT = 3600.0

_ALLOWED_KEYS = {"source", "owner", "name", "private", "interval"}


class SeedError(Exception):
    """An expected seeder failure."""


@dataclass(frozen=True)
class MirrorSpec:
    source: str
    owner: str
    name: str
    private: bool
    interval: str

    @property
    def source_url(self) -> str:
        return f"https://github.com/{self.source}.git"


def _string(raw: dict[str, Any], key: str, where: str) -> str:
    value = raw.get(key)
    if not isinstance(value, str) or not value.strip():
        raise SeedError(f"{where}: {key!r} must be a non-empty string")
    return value.strip()


def load_manifest(path: Path) -> list[MirrorSpec]:
    try:
        raw_text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise SeedError(f"cannot read manifest {path}: {exc}") from exc

    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise SeedError(f"invalid JSON in {path}: {exc}") from exc

    if not isinstance(data, list):
        raise SeedError("manifest must be a JSON array")

    specs: list[MirrorSpec] = []
    seen_targets: set[str] = set()

    for index, raw in enumerate(data, start=1):
        where = f"entry {index}"
        if not isinstance(raw, dict):
            raise SeedError(f"{where}: must be an object")

        unknown = sorted(set(raw) - _ALLOWED_KEYS)
        if unknown:
            raise SeedError(f"{where}: unknown key(s): {', '.join(unknown)}")

        source = _string(raw, "source", where)
        source_parts = source.split("/")
        if len(source_parts) != 2 or not all(source_parts):
            raise SeedError(
                f"{where}: source must have the form owner/repo"
            )

        owner = _string(raw, "owner", where)
        if "/" in owner:
            raise SeedError(f"{where}: owner must not contain '/'")

        name = raw.get("name", source_parts[1])
        if not isinstance(name, str) or not name.strip() or "/" in name:
            raise SeedError(
                f"{where}: name must be a non-empty repository name"
            )
        name = name.strip()

        target = f"{owner}/{name}".lower()
        if target in seen_targets:
            raise SeedError(f"{where}: duplicate destination {owner}/{name}")
        seen_targets.add(target)

        private = raw.get("private", True)
        if not isinstance(private, bool):
            raise SeedError(f"{where}: 'private' must be a boolean")

        interval = raw.get("interval", DEFAULT_INTERVAL)
        if not isinstance(interval, str) or not interval.strip():
            raise SeedError(
                f"{where}: 'interval' must be a non-empty string"
            )

        specs.append(
            MirrorSpec(
                source=source,
                owner=owner,
                name=name,
                private=private,
                interval=interval.strip(),
            )
        )

    return specs


def _clean_secret(value: str, source: str) -> str:
    value = value.strip()
    if not value:
        raise SeedError(f"{source} is empty")
    return value


def _read_secret(
    path: str | None,
    credential_name: str,
    environment_names: tuple[str, ...],
) -> str:
    if path is not None:
        try:
            return _clean_secret(
                Path(path).read_text(encoding="utf-8"),
                path,
            )
        except OSError as exc:
            raise SeedError(f"cannot read {path}: {exc}") from exc

    credentials_directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if credentials_directory:
        credential_path = Path(credentials_directory) / credential_name
        if credential_path.is_file():
            try:
                return _clean_secret(
                    credential_path.read_text(encoding="utf-8"),
                    str(credential_path),
                )
            except OSError as exc:
                raise SeedError(
                    f"cannot read credential {credential_name}: {exc}"
                ) from exc

    for name in environment_names:
        value = os.environ.get(name)
        if value:
            return _clean_secret(value, name)

    names = ", ".join(environment_names)
    raise SeedError(
        f"missing {credential_name}; provide --{credential_name}-file, "
        f"CREDENTIALS_DIRECTORY/{credential_name}, or {names}"
    )


def _response_message(response: requests.Response) -> str:
    try:
        payload = response.json()
    except ValueError:
        payload = None

    if isinstance(payload, dict):
        message = payload.get("message") or payload.get("error")
        if message:
            return str(message)

    text = response.text.strip()
    return text[:500] if text else response.reason or "no response body"


def _json_object(
    response: requests.Response,
    action: str,
) -> dict[str, Any]:
    try:
        payload = response.json()
    except ValueError as exc:
        raise SeedError(f"{action} returned invalid JSON") from exc
    if not isinstance(payload, dict):
        raise SeedError(f"{action} returned non-object JSON")
    return payload


class ForgejoClient:
    def __init__(
        self,
        base_url: str,
        token: str,
        *,
        timeout: float,
        migrate_timeout: float,
        secrets: tuple[str, ...],
    ) -> None:
        self.api_url = base_url.rstrip("/") + "/api/v1"
        self.timeout = timeout
        self.migrate_timeout = migrate_timeout
        self._secrets = tuple(secret for secret in secrets if secret)
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"token {token}",
                "Accept": "application/json",
                "User-Agent": "forgejo-mirror-seeder",
            }
        )

    def _repo_path(self, owner: str, name: str) -> str:
        return (
            f"/repos/{quote(owner, safe='')}/"
            f"{quote(name, safe='')}"
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        expected: set[int],
        timeout: float | None = None,
        json_body: dict[str, Any] | None = None,
    ) -> requests.Response:
        try:
            response = self.session.request(
                method,
                self.api_url + path,
                json=json_body,
                timeout=self.timeout if timeout is None else timeout,
            )
        except requests.RequestException as exc:
            raise SeedError(f"{method} {path} failed: {exc}") from exc

        if response.status_code not in expected:
            message = _response_message(response)
            for secret in self._secrets:
                message = message.replace(secret, "<redacted>")
            raise SeedError(
                f"{method} {path} returned HTTP {response.status_code}: "
                f"{message}"
            )
        return response

    def get_repo(self, owner: str, name: str) -> dict[str, Any] | None:
        path = self._repo_path(owner, name)
        response = self._request("GET", path, expected={200, 404})
        if response.status_code == 404:
            return None
        return _json_object(response, f"GET {path}")

    def create_mirror(self, spec: MirrorSpec, github_token: str) -> None:
        payload = {
            "clone_addr": spec.source_url,
            "repo_owner": spec.owner,
            "repo_name": spec.name,
            "service": "github",
            "auth_token": github_token,
            "mirror": True,
            "mirror_interval": spec.interval,
            "private": spec.private,
        }
        response = self._request(
            "POST",
            "/repos/migrate",
            expected={201},
            timeout=self.migrate_timeout,
            json_body=payload,
        )
        created = _json_object(response, "POST /repos/migrate")
        if not created.get("mirror"):
            current = self.get_repo(spec.owner, spec.name)
            if current is None or not current.get("mirror"):
                raise SeedError(
                    "Forgejo created the repository but did not mark it "
                    "as a mirror"
                )


def _normalized_source_url(value: str) -> str:
    text = value.strip().rstrip("/").removesuffix(".git")
    for prefix in ("https://", "http://"):
        text = text.removeprefix(prefix)
    return text.lower()


def reconcile(
    client: ForgejoClient,
    spec: MirrorSpec,
    github_token: str | None,
    dry_run: bool,
) -> str:
    existing = client.get_repo(spec.owner, spec.name)

    if existing is None:
        if dry_run:
            return "would-create"
        if github_token is None:
            raise SeedError("GitHub token is required to create mirrors")
        client.create_mirror(spec, github_token)
        return "created"

    if not existing.get("mirror"):
        raise SeedError(
            "destination exists but is not a pull mirror; "
            "Forgejo cannot convert it in place"
        )

    actual_source = existing.get("original_url") or ""
    if _normalized_source_url(actual_source) != _normalized_source_url(
        spec.source_url
    ):
        raise SeedError(
            f"destination mirrors {actual_source or 'an unknown source'}, "
            f"expected {spec.source_url}"
        )

    return "unchanged"


def run(args: argparse.Namespace) -> int:
    specs = load_manifest(Path(args.manifest))

    forgejo_url = args.forgejo_url or os.environ.get("FORGEJO_URL")
    if not forgejo_url:
        raise SeedError(
            "missing Forgejo URL; provide --forgejo-url or FORGEJO_URL"
        )

    forgejo_token = _read_secret(
        args.forgejo_token_file,
        "forgejo-token",
        ("FORGEJO_TOKEN", "GITEA_TOKEN"),
    )
    github_token = None
    if not args.dry_run:
        github_token = _read_secret(
            args.github_token_file,
            "github-token",
            ("GITHUB_TOKEN", "GH_TOKEN"),
        )

    secrets = tuple(
        token for token in (forgejo_token, github_token) if token
    )
    client = ForgejoClient(
        forgejo_url,
        forgejo_token,
        timeout=args.timeout,
        migrate_timeout=args.migrate_timeout,
        secrets=secrets,
    )

    counts: Counter[str] = Counter()
    failures = 0

    if not specs:
        LOGGER.warning("manifest contains no repositories")

    for spec in specs:
        try:
            status = reconcile(client, spec, github_token, args.dry_run)
        except SeedError as exc:
            failures += 1
            counts["failed"] += 1
            LOGGER.error("%s/%s: %s", spec.owner, spec.name, exc)
            continue

        counts[status] += 1
        LOGGER.info("%s/%s: %s", spec.owner, spec.name, status)

    summary = ", ".join(
        f"{count} {status}" for status, count in sorted(counts.items())
    )
    LOGGER.info("summary: %s", summary or "nothing to do")

    return 1 if failures else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Reconcile Forgejo pull mirrors from a JSON manifest."
    )
    parser.add_argument(
        "--manifest",
        required=True,
        help="path to the JSON manifest",
    )
    parser.add_argument(
        "--forgejo-url",
        default=None,
        help="Forgejo base URL; defaults to FORGEJO_URL",
    )
    parser.add_argument(
        "--forgejo-token-file",
        default=None,
        help="file containing the Forgejo API token",
    )
    parser.add_argument(
        "--github-token-file",
        default=None,
        help="file containing the GitHub token",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT,
        help=f"request timeout in seconds (default: {DEFAULT_TIMEOUT:g})",
    )
    parser.add_argument(
        "--migrate-timeout",
        type=float,
        default=DEFAULT_MIGRATE_TIMEOUT,
        help=(
            "timeout for the initial clone in seconds "
            f"(default: {DEFAULT_MIGRATE_TIMEOUT:g})"
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report planned changes without modifying Forgejo",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="enable debug logging",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
        stream=sys.stderr,
    )

    try:
        return run(args)
    except SeedError as exc:
        LOGGER.error("%s", exc)
        return 2


if __name__ == "__main__":
    sys.exit(main())
