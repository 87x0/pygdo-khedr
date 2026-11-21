#!/usr/bin/env bash
# dog-watchdog.sh (cron, every minute): restart the pygdo Dog if it died. Log: ~/data/dog-watchdog.log
# Approved by X (Pilot) in GRYYX 2026-11-21 10:41 UTC after the 10:16 Dog crash (bug #18).
export PATH="$HOME/.py314/bin:$HOME/.local/node/bin:/usr/local/bin:/usr/bin:/bin"
LOG="$HOME/data/dog-watchdog.log"
exec 9>"$HOME/data/.dog-watchdog.lock"; flock -n 9 || exit 0
if ! "$HOME/data/dog.sh" status | grep -q '^RUNNING'; then
  echo "$(date -u '+%F %T') Dog down -> restart" >> "$LOG"
  "$HOME/data/dog.sh" start >> "$LOG" 2>&1
fi
