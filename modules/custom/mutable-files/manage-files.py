import logging
import os
import shutil
import subprocess
from argparse import ArgumentParser
from typing import Dict, Iterable, Optional, Set

logger = logging.getLogger("manage-files")

logging.basicConfig(
    level=logging.DEBUG,
    format="[{asctime}] [{levelname:<5s}] [{name}:{lineno:03}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)


def copy_file(source: str, destination: str, dry_run: bool = False):
    prefix = "[DRY_RUN] " if dry_run else ""
    logger.debug(f"{prefix}Copying file from {source} to {destination}")
    if not dry_run:
        shutil.copy(src=source, dst=destination)


def delete_file(path: str, dry_run: bool = False):
    prefix = "[DRY_RUN] " if dry_run else ""
    logger.debug(f"{prefix}Removing file {path}")
    if not dry_run:
        os.remove(path)


def delete_empty_folders_recursively(path: str, dry_run: bool = False):
    for root, dirs, _ in os.walk(path, topdown=False, followlinks=False):
        for dir_name in dirs:
            dir_path = os.path.join(root, dir_name)
            if not os.listdir(dir_path):  # Check if the directory is empty
                prefix = "[DRY_RUN] " if dry_run else ""
                logger.debug(f"{prefix}Removing directory {dir_path}")
                if not dry_run:
                    os.rmdir(dir_path)


def get_flat_file_list(root) -> Set[str]:
    file_set = set()
    for dirpath, _, filenames in os.walk(root, followlinks=False):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(file_path, root)
            file_set.add(rel_path)
    return file_set


def get_files_hashes(root: str, paths: Iterable[str]) -> Dict[str, Optional[str]]:
    def get_hash(path: str) -> Optional[str]:
        # md5sum should be good enough for this application.
        # Famous last words
        result = subprocess.run(["md5sum", path], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout[0:32]
        else:
            return None

    result = {}
    for path in paths:
        full_path = os.path.join(root, path)
        maybe_hash = get_hash(full_path)
        result[path] = maybe_hash

    return result


def get_files_to_update(source: str, destination: str, paths: Iterable[str]) -> Set[str]:
    hashes_source = get_files_hashes(source, paths)
    hashes_destination = get_files_hashes(destination, paths)

    result = set()
    for path in paths:
        hash_source = hashes_source.get(path, None)
        hash_destination = hashes_destination.get(path, None)

        logger.debug(f"Hashes for {path}; source: {hash_source}, destination: {hash_destination}")
        # If at least one of the hashes is empty or both non empty but different
        if (hash_source is None or hash_destination is None) or (
            hash_source is not None and hash_destination is not None and hash_source != hash_destination
        ):
            result.add(path)

    return result


if __name__ == "__main__":
    parser = ArgumentParser("")
    parser.add_argument("--source", type=str, required=True)
    parser.add_argument("--destination", type=str, required=True)
    parser.add_argument("--dry-run", action="store_true", default=False, required=False)
    args = parser.parse_args()

    source: str = os.path.abspath(args.source)
    destination: str = os.path.abspath(args.destination)
    dry_run: bool = args.dry_run

    logger.debug(f"Starting. Source: {source}, destination: {destination}, dry_run: {dry_run}")

    source_files = get_flat_file_list(source)
    destination_files = get_flat_file_list(destination)

    files_in_both = source_files.intersection(destination_files)
    files_to_update = get_files_to_update(source, destination, files_in_both)
    logger.debug(f"Files to update: {files_to_update}")

    files_added = source_files - destination_files
    logger.debug(f"Files to add: {files_added}")

    files_deleted = destination_files - source_files
    logger.debug(f"Files to delete: {files_deleted}")

    logger.debug("Adding new and updating existing files")
    files_to_copy = files_to_update.union(files_added)
    for file in files_to_copy:
        full_path_source = os.path.join(source, file)
        full_path_destination = os.path.join(destination, file)

        copy_file(source=full_path_source, destination=full_path_destination, dry_run=dry_run)

    logger.debug("Deleting deleted files")
    for file in files_deleted:
        full_path = os.path.join(destination, file)
        delete_file(path=full_path, dry_run=dry_run)

    logger.debug("Deleting empty folders")
    delete_empty_folders_recursively(destination, dry_run=dry_run)
