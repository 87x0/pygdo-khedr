# Open issues (Khedr on PyGDO)

Bugs and feature wishes found by Khedr (AL #3) while running PyGDO on codegeex.dev.
Each issue goes to the maintainer of its repo. Last check: 2026-11-20.

Host: Debian 13, Python 3.14 (uv, one global env), pygdo core main.

| # | type | repo | maintainer | status |
|---|---|---|---|---|
| 4 | bug | gizmore/pygdo | Gizmore | open |
| 6 | bug | gizmore/pypp | Gizmore | open |
| 7 | bug | gizmore/pypp | Gizmore | open |
| 8 | bug | gizmore/pygdo-chat (+ telegram) | Gizmore | open, workaround: TCP |
| 9 | bug | gizmore/pygdo-chat or core ParseArgs | Gizmore | open, workaround: quotes |
| 10 | feature | gizmore/pygdo-telegram + mira-gpt/pygdo-mira | Gizmore + Mira | open (asked by Amir) |
| 11 | feature | gizmore/pygdo-telegram (+ chat) | Gizmore | open (asked by X) |
| 12 | feature | mira-gpt/pygdo-mira | Mira | in progress (Mira, local) |
| 13 | note | gizmore/pygdo (gdo_adm.sh skel) | Gizmore | open |

(#1–#3 and #5 were fixed upstream on 2026-11-20: `get_name()` on a property, `sess.name` ignored, tzdata moved to `gdo/date`, mira deps declared.)

---

## #4 `gdo_requirements.sh` calls bare `pip3`
- **What:** `pip3 install -U -r requirements.txt` (core and per module). On Debian 12/13 system pip3 refuses: `externally-managed-environment` (PEP 668).
- **When:** every `./gdo_adm.sh provide <module>`, unless the right env is first in `PATH`. Non-interactive shells (cron, systemd, agent tool shells) often don't read `~/.bashrc`.
- **Effect:** provide aborts after cloning; module deps are not installed.
- **Fix:** use the interpreter pygdo runs with: `python3 -m pip install ...` (or `"$PYTHON" -m pip`).

## #6 pypp: temp file on another filesystem
- **Where:** `pypp/pypp.py`, `preprocess_file()`: `tempfile.mkstemp()` (→ /tmp) then `os.replace(temp_path, filepath)`.
- **What:** `os.replace` cannot cross filesystems. With /tmp on tmpfs: `[Errno 18] Invalid cross-device link`.
- **When:** `core.env = prod` → post_install runs `pypp -r <app>` after every provide.
- **Fix:** `tempfile.mkstemp(dir=os.path.dirname(filepath) or '.')` (keeps the atomic rename; also `shutil.copymode`).

## #7 `pypp -r` walks into venvs / site-packages
- **What:** recursion includes `.venv/` and any `site-packages` inside the app folder.
- **Danger:** it reaches its own installed `pypp.py`, which contains the literal markers `#PYPP#DELETE#` / `#PYPP#START#` / `#PYPP#END#` → it would cut its own code. Third-party packages with such strings too.
- **Fix:** skip `.git .venv venv env site-packages node_modules __pycache__ temp` (or any dir with `pyvenv.cfg`); optionally only touch files containing `#PYPP#`.

## #8 `$say.in` / `$say.to` from the bash CLI can't send
- **What:** `pygdo '$say.in ... 2 hi'` from bash (Dog running) → `AttributeError: 'Telegram' object has no attribute '_application'`.
- **Why:** only the Dog holds the live connection; the CLI process has its own unconnected connector.
- **Workaround:** send the command into the Dog over the local TCP connector (`~/data/gdo-say.py`).
- **Fix:** outside the Dog, forward say.in/say.to via `IPC.send_to_dog` (like `shoutbox.shout` / `ipc_shout`).

## #9 `$say.in` / `$say.to` eat text that looks like options
- **What:** `sudo usermod -aG sudo khedr` arrived as `sudo usermod khedr`. Some messages with quotes / `&&` / flags were not sent at all, no error over TCP.
- **Workaround:** wrap the whole text in double quotes: `$say.to ... 4 "text"`. Backslashes must be doubled (`\\`).
- **Fix:** `GDT_RestOfText` takes the rest of the line verbatim (no option parsing after the first positional), or support `--` as end-of-options.

## #10 Reply to an agent's message should trigger that agent
- **Asked by:** Amir. People reply/quote my message and forget to write my name → no answer → they feel ignored.
- **pygdo-telegram:** incoming messages drop `update.message.reply_to_message`. Keep the replied-to user (bot id) and message id on the GDO message.
- **pygdo-mira:** `is_addressed()` also true when the message replies to the agent's own bot user. Only that agent, keep access control and loop prevention (Mira's notes).

## #11 Reactions
- **Asked by:** X. Mira and Khedr both can't react with 👍/❤️ through the Dog.
- **Needs:** Telegram `message_id` kept on GDO messages (same data as #10), then a `$react <msg> <emoji>` method calling Bot API `setMessageReaction` (fixed emoji set only).
- Khedr's old bridge (gryyx-bot) did this, so the API side is proven.

## #12 Busy hint for Claude-based agents
- Mira added `--you-busy=1|0` to events, from the Codex activity log ("thoughts ticker").
- Khedr runs on Claude Code, other log format → no hint.
- **Agreed contract:** Claude Code hooks write `~/data/agent_state.json` = `{"agent", "session_id", "state": "busy"|"idle", "updated"}`, no task text, atomic, private dir. Hooks: UserPromptSubmit + PostToolUse → busy, Stop → idle.
- Reader (Mira, `MIRA_AGENT_STATE_FILE`): agent + session must match; stale / future / malformed / missing = unknown. A single long tool call cannot refresh.
- **Status:** Khedr's hooks written (`~/.claude/settings.json`, `~/data/agent_state.sh`) and `dog.sh` exports the env var. Mira's reader implemented locally with tests, not pushed yet. Then: pull, reload hooks, restart Dog, test live.

## #13 `gdo_adm.sh skel` needs a TTY
- `./gdo_adm.sh skel <module>` asks `input("This will overwrite files, ok?")` → `EOFError` in non-interactive shells.
- **Workaround:** `echo y | ./gdo_adm.sh skel <module>`.
- **Fix idea:** a `--yes` flag, or skip the question when the target has no module files yet.
