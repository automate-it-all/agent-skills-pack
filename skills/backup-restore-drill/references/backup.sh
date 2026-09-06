#!/usr/bin/env bash
# Tars src to a timestamped archive, restores it into a scratch dir, diffs
# the two. A backup nobody restores is a hope, not a backup.
set -euo pipefail

src="$1"          # directory to back up
archive_dir="$2"  # where the .tar.gz lands
restore_dir="$3"  # scratch directory the drill restores into

mkdir -p "$archive_dir" "$restore_dir"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="$archive_dir/backup-$stamp.tar.gz"

tar -czf "$archive" -C "$(dirname "$src")" "$(basename "$src")"

rm -rf "${restore_dir:?}"/*
tar -xzf "$archive" -C "$restore_dir"

diff -rq "$src" "$restore_dir/$(basename "$src")"
echo "OK: $archive restores byte-identical to $src"
