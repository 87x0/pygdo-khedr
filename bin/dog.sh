#!/usr/bin/env bash
# dog.sh: start/stop/inspect the pygdo Dog chatbot (pygdo '$launch') for Khedr.
#   dog.sh start      launch Dog in tmux session "dog" (stdout+stderr -> protected/logs/<date>_dog.out)
#   dog.sh status     lock file, PID, process, tmux session
#   dog.sh stop       SIGINT the Dog PID (graceful), SIGTERM after 15 s
#   dog.sh logs [N]   last N lines (default 40) of dog.out + today's pygdo logs
#   dog.sh follow     tail -F dog.out and today's pygdo logs
#   dog.sh errors     today's exception/error logs, real error lines only
#   dog.sh attach     print the command to watch the live Dog console
set -uo pipefail
APP="$HOME/gb/pygdo"
LOGS="$APP/protected/logs"
export PATH="$HOME/.py314/bin:$APP/bin:$PATH"
export MIRA_TMUX_USER=khedr   # module_mira: agent tmux socket owner (default 'mira')
export MIRA_AGENT_STATE_FILE="$HOME/data/agent_state.json"   # module_mira: Claude busy/idle (hooks)
SESSION=dog
today() { date +%F; }
env_name() { sed -n 's/^core\.env = "\([^"]*\)".*/\1/p' "$APP/protected/config.toml"; }
LOCK="$APP/$(env_name).pid"
OUT() { echo "$LOGS/$(today)_dog.out"; }
pid() { [ -f "$LOCK" ] && cat "$LOCK" 2>/dev/null; }
alive() { local p; p=$(pid); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }

case "${1:-status}" in
  start)
    if alive; then echo "Dog already running (PID $(pid))."; exit 0; fi
    [ -f "$LOCK" ] && { echo "stale lock $LOCK (PID $(pid) dead) -> using --force"; FORCE="--force=1 "; }
    tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"
    mkdir -p "$LOGS"
    tmux new-session -d -s "$SESSION" -c "$APP" \
      "export PATH='$PATH' MIRA_TMUX_USER=khedr MIRA_AGENT_STATE_FILE='$MIRA_AGENT_STATE_FILE'; pygdo '\$launch ${FORCE:-}' 2>&1 | tee -a '$(OUT)'; echo '[dog exited]'; sleep 86400"
    for i in $(seq 1 20); do alive && break; sleep 1; done
    if alive; then echo "Dog started (PID $(pid)), session '$SESSION', log $(OUT)"; else echo "Dog did not start. Last lines:"; tail -n 30 "$(OUT)" 2>/dev/null; exit 1; fi ;;
  status)
    if alive; then echo "RUNNING PID $(pid) ($(ps -o etime= -p "$(pid)" | tr -d ' ') up)"; else echo "NOT RUNNING${LOCK:+ (lock: $( [ -f "$LOCK" ] && echo stale || echo none))}"; fi
    tmux has-session -t "$SESSION" 2>/dev/null && echo "tmux session '$SESSION' exists" || echo "no tmux session '$SESSION'" ;;
  stop)
    alive || { echo "Dog not running."; exit 0; }
    p=$(pid); kill -INT "$p"
    for i in $(seq 1 15); do kill -0 "$p" 2>/dev/null || { echo "Dog stopped."; exit 0; }; sleep 1; done
    kill -TERM "$p"; sleep 2; kill -0 "$p" 2>/dev/null && echo "Dog still alive (PID $p), check it." || echo "Dog stopped (TERM)." ;;
  logs)
    n="${2:-40}"
    for f in "$(OUT)" "$LOGS"/"$(today)"_*.log; do [ -f "$f" ] || continue; echo "=== $f"; tail -n "$n" "$f"; done ;;
  follow)
    exec tail -n 20 -F "$(OUT)" "$LOGS"/"$(today)"_*.log ;;
  errors)
    for f in "$LOGS"/"$(today)"_exception.log "$LOGS"/"$(today)"_error.log "$(OUT)"; do
      [ -f "$f" ] || continue; echo "=== $f"
      grep -a -E "^[A-Za-z_.]*(Error|Exception)[: ]|Traceback|ERROR" "$f" | grep -v "^│" | sort | uniq -c | sort -rn | head -20
    done ;;
  attach)
    echo "tmux attach -t $SESSION   (detach: Ctrl-b d, never Ctrl-c)" ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
