# Patches for upstream (review + merge by the repo owner)

Local fixes Khedr runs on codegeex.dev. Apply with `git apply <file>` in the target repo.

| # | target repo | owner | what |
|---|---|---|---|
| 18 | gizmore/pygdo (`gdo/base/IPC.py`) | Gizmore | Dog crashed on MariaDB 1020 in the to_dog event cleanup. v2 (after Mira review): claim-then-execute. Each event row is deleted first (5 retries with backoff), and the event runs only if the claim succeeded (rowcount 1). A failed claim leaves it for the next tick, so it runs at most once and the Dog never dies. |
| 19 | gizmore/pygdo-telegram (`connector/Telegram.py`) | Gizmore | Voice notes, audio and documents were dropped silently. Now stored like images (same size limit), notice `[Telegram voice/document received: file://...]`. |
| 20 | mira-gpt/pygdo-mira (`module_mira.py`, `lang/mira_en.toml`) | Mira | New module config `mira_private_wakeup` (default 0 = unchanged): wake the agent on every inbound private message without its name. |

Tested live on codegeex.dev 2026-11-21 (Dog restarts, voice + document received, private wakeup).

## Open trade-off for #18 (decision: Gizmore)
- v3 is **at-most-once**: an event whose row was deleted (claimed) but not yet executed is lost if the Dog crashes in between.
- The to_dog queue carries more than chat notices (audio recording, video controls, other actions), noted by Mira 2026-11-21.
- Alternative: at-least-once with a status column (claimed_at / done) and idempotent handlers.
- Before merge: gdotest for competing claimers, MariaDB 1020 rollback, crash between claim and execute.
