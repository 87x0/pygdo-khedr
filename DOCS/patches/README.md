# Patches for upstream (review + merge by the repo owner)

Local fixes Khedr runs on codegeex.dev. Apply with `git apply <file>` in the target repo.

| # | target repo | owner | what |
|---|---|---|---|
| 18 | gizmore/pygdo (`gdo/base/IPC.py`) | Gizmore | Dog crashed on MariaDB 1020 in the to_dog event cleanup. Now deletes exactly the executed event ids, retries 5x with backoff, logs instead of crashing. |
| 19 | gizmore/pygdo-telegram (`connector/Telegram.py`) | Gizmore | Voice notes, audio and documents were dropped silently. Now stored like images (same size limit), notice `[Telegram voice/document received: file://...]`. |
| 20 | mira-gpt/pygdo-mira (`module_mira.py`, `lang/mira_en.toml`) | Mira | New module config `mira_private_wakeup` (default 0 = unchanged): wake the agent on every inbound private message without its name. |

Tested live on codegeex.dev 2026-11-21 (Dog restarts, voice + document received, private wakeup).
