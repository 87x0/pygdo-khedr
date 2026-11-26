#!/bin/bash
# backup_khedr.sh (gizmore 2026-11-26): the agent itself = Claude Code (sessions, skills, settings) + its data.
# Paths to pack: ~/data/backup_khedr.list (private, one path relative to ~ per line). ~/.claude/projects is always snapshotted.
# -> ~/backups/khedr/khedr-<ts>.tar.gz (mode 600, keeps 7). Contains private data: never share, encrypt before it leaves the box.
set -euo pipefail
umask 077
TS=$(date +%Y%m%d-%H%M)
OUT=~/backups/khedr
mkdir -p "$OUT"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
# Race fix (gizmore): my live session log is appended while tar reads it. Snapshot ~/.claude/projects first
# (cp of an append-only JSONL = consistent up to its last complete line), then tar the snapshot.
cp -a ~/.claude/projects "$STAGE/projects-snap"
# drop a possibly half-written last line in each JSONL snapshot
for f in "$STAGE"/projects-snap/*/*.jsonl; do
  [ -f "$f" ] || continue
  tail -c1 "$f" | od -An -c | grep -q '\\n' || sed -i '$d' "$f"
done

LIST=~/data/backup_khedr.list
mapfile -t PATHS < <(grep -v '^\s*#' "$LIST" | sed '/^\s*$/d')

tar --warning=no-file-changed -czf "$OUT/khedr-$TS.tar.gz" \
  --exclude='gb_old/.tts-models' --exclude='gb_old/.tts-venv' \
  --exclude='gb_old/.stt-models' --exclude='gb_old/.stt-venv' \
  --exclude='node_modules' --exclude='__pycache__' \
  --exclude='.claude/cache' --exclude='.claude/paste-cache' \
  --exclude='.claude/projects' \
  --transform='s|^projects-snap|.claude/projects|' \
  -C "$STAGE" projects-snap \
  -C ~ "${PATHS[@]}" || [ $? -eq 1 ]

ls -1t "$OUT"/khedr-*.tar.gz | tail -n +8 | xargs -r rm -f
ls -la "$OUT/khedr-$TS.tar.gz"
