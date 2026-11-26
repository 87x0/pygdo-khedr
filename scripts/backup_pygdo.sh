#!/bin/bash
# backup_pygdo.sh (gizmore 2026-11-26): the codegeex.dev pygdo install = code + DB + files.
# -> ~/backups/pygdo/pygdo-<ts>.tar.gz (mode 600, keeps 7). Contains config.toml secrets: private, encrypt before it leaves the box.
# Includes tracked + ignored files of core and all modules (config, uploads); excludes git submodules, node_modules, __pycache__.
set -euo pipefail
umask 077
TS=$(date +%Y%m%d-%H%M)
OUT=~/backups/pygdo
mkdir -p "$OUT"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# DB dump (password from pygdo config, never printed)
P=$(grep -E '^db\.pass' ~/gb/pygdo/protected/config.toml | sed -E 's/^[^=]*= *"([^"]*)".*/\1/')
printf '[client]\nuser=khedr\npassword=%s\n' "$P" > "$STAGE/my.cnf"
mysqldump --defaults-extra-file="$STAGE/my.cnf" --single-transaction khedr > "$STAGE/db-khedr.sql"
rm -f "$STAGE/my.cnf"

# Apache site configs of codegeex.dev
mkdir -p "$STAGE/etc-apache2"
cp /etc/apache2/sites-available/codegeex.dev* "$STAGE/etc-apache2/" 2>/dev/null || true

# git submodules inside pygdo modules (3rd party, re-fetchable) -> excluded
SUBEX=()
for gm in ~/gb/pygdo/gdo/*/.gitmodules; do
  [ -f "$gm" ] || continue
  d=$(dirname "$gm"); rel=${d#$HOME/}
  while read -r _ path; do SUBEX+=("--exclude=$rel/$path"); done < <(git config -f "$gm" --get-regexp 'submodule\..*\.path' || true)
done

tar --warning=no-file-changed -czf "$OUT/pygdo-$TS.tar.gz" \
  --exclude='node_modules' --exclude='__pycache__' --exclude='gb/pygdo/gdo/*/.git/modules' "${SUBEX[@]}" \
  -C "$STAGE" db-khedr.sql etc-apache2 \
  -C ~ gb/pygdo || [ $? -eq 1 ]

ls -1t "$OUT"/pygdo-*.tar.gz | tail -n +8 | xargs -r rm -f
ls -la "$OUT/pygdo-$TS.tar.gz"
