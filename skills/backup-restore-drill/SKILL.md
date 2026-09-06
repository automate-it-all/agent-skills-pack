---
name: backup-restore-drill
description: Take a backup, then prove it restores, before trusting it.
version: 0.1.0
author: agent-skills-pack
license: MIT
platforms: [linux]
---

# Backup Restore Drill

## Overview

A backup job that only ever writes is unverified: the first time anyone
reads the archive back is the outage. This skill pairs every backup with an
immediate restore into a scratch directory and a diff against the source,
so a broken archive fails the same day it was made, not months later.

## Steps

1. Run the backup script against the directory to protect, an archive
   directory, and a scratch restore directory:

       references/backup.sh /path/to/data /path/to/archives /path/to/restore-scratch

2. The script tars the source, extracts that same archive into the scratch
   directory, and runs `diff -rq` between the two trees. A clean diff and
   `OK: ... restores byte-identical to ...` on stdout is the pass condition.
3. Wire step 1 into cron or a systemd timer for the real schedule; keep the
   restore-and-diff in the same invocation, never split into a separate job
   nobody checks.
4. Prune old archives on a retention window (`find "$archive_dir" -name
   'backup-*.tar.gz' -mtime +30 -delete` for 30 days) so the drill does not
   fill the disk it runs on.

## Verification

- `references/backup.sh` exits 0 and prints the `OK: ... byte-identical`
  line; a nonzero exit is a broken backup, not a warning to note.
- The archive directory holds a new `backup-<UTC timestamp>.tar.gz` file
  after each run.

## Troubleshooting

- `diff -rq` reports a mismatch: the source changed mid-tar (a file written
  during the backup window). Snapshot the source first (LVM snapshot, or
  briefly stop the writer) rather than taming the diff.
- The restore step fails with "No space left on device": the scratch
  restore directory shares a disk with the archive directory; point
  `restore_dir` at separate storage, since a drill that does not unpack
  proves nothing about the real restore target.
- Permissions differ after restore (`diff` reports content-identical but
  ownership wrong): `tar` preserves ownership only when run as root; run
  the drill as root or add `--no-same-owner` and check permissions
  separately if the source expects a specific owner.
- Cron runs the drill but nobody sees a failure: pipe the script's exit
  code into an alert (`|| mail -s "backup drill failed" ops@example.com`
  or the `service-health-check` skill's own alert path), since a silent
  cron failure is worse than the missing backup it hid.
