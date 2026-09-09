---
name: anki-connect
description: Reads and manages Anki decks, notes, cards, models, media, and sync through the AnkiConnect API. Use when the user asks to inspect or modify Anki data, review or reschedule cards, import collections, manage media, sync Anki, or update this skill from upstream AnkiConnect.
---

# AnkiConnect

## Quick start

Anki must be running with the AnkiConnect add-on installed (code `2055492159`). Use loopback `http://127.0.0.1:8765` unless configured otherwise. Requires Bash, curl, and jq for these examples.

Check readiness with the read-only `version` action:

```bash
set -o pipefail
jq -n --arg key "${ANKI_CONNECT_API_KEY:-}" \
  '{action:"version", version:6} +
   (if $key == "" then {} else {key:$key} end)' \
| curl -fsS --max-time 15 http://127.0.0.1:8765 \
    -H 'Content-Type: application/json' -d @- \
| jq 'if type != "object" then error("invalid AnkiConnect response")
      elif (has("result") and has("error") | not) then error("missing response fields")
      elif .error != null then error(.error)
      else .result end'
```

Use `deckNames` instead of `version` to list decks. Do not add `jq -e`: successful results can be `null` or `false`.

## Read-only helpers

Prefer these scripts over rewriting request code. Paths below are relative to this skill directory; both require Bash, curl, and jq.

```bash
scripts/deck-count.sh "Korean Vocabulary"
scripts/fetch-notes.sh 'deck:"Korean Vocabulary"' > /tmp/anki-notes.json
```

- [deck-count.sh](scripts/deck-count.sh) takes an exact deck name and returns compact JSON with separate `cards` and `notes` totals, **including subdecks** and suspended/buried cards. Unknown decks fail rather than returning zero. Anki's reserved search names `current` and `filtered` are rejected.
- [fetch-notes.sh](scripts/fetch-notes.sh) takes any nonempty Anki search query and emits the original `notesInfo` array (IDs, fields, tags, model, and card IDs). Fetches in batches of 500; no matches returns `[]`. Redirect large results to a file, then inspect only needed fields. No partial JSON is emitted if a batch fails.
- Both support `--help`, use version 6 and optional `ANKI_CONNECT_API_KEY`, and exit nonzero on transport/API errors. Set `ANKI_CONNECT_URL` only for a configured nondefault endpoint; keep it on loopback unless remote access is explicitly approved. Each request times out after 30 seconds; neither script retries.
- These are live reads, not atomic snapshots or backups. Re-fetch before writes; counts can change between requests. Note/card IDs are distinct, and sibling cards returned by `notesInfo` may live outside the queried deck.

## Safety and confirmation

**Always request and receive confirmation before any operation that adds, modifies, or deletes notes or cards.** Ask once per logical operation, describing intent, scope, and affected count when known. Use `AskUserQuestion` if available; otherwise ask in chat. Read-only discovery and previews can precede confirmation.

This includes:
- Adding/deleting notes; editing fields, tags, or note types; removing empty notes or unused tags.
- Moving, suspending, unsuspending, rescheduling, or changing card properties; answering cards, inserting reviews, or undoing reviews.
- Imports and deck/model/scheduling-configuration changes that materially affect notes or cards.
- Media deletion or overwrites that affect existing notes or cards.

Apply this rule even to unlisted actions and actions nested inside `multi`. Deck deletion must explicitly confirm deletion of its cards; retaining them via `deleteDecks` is not supported.

**Before any deck-affecting write, make and verify a fresh backup of every affected existing deck, following [BACKUP.md](BACKUP.md).** This includes note/card edits, additions, deletions, reviews, moves, imports, sync, and indirect model/configuration/media changes. Back up once per confirmed logical operation, before its first write; if scope expands, back up the newly affected decks first. If backup fails or coverage is uncertain, stop—never proceed unprotected.

Keep API access on loopback unless remote access is explicitly requested. Never broaden bind addresses or CORS permissions to fix connectivity. Never print or commit API keys.

## Workflow

1. **Connect.** Launch Anki if needed and call `version` with API version 6 and any configured key. Respect configured `webBindAddress`/`webBindPort`. On macOS, foreground Anki or disable App Nap if requests stall.
2. **Discover.** Use `apiReflect` with `scopes:["actions"]` for installed action names. It does not provide parameter schemas; consult upstream documentation or implementation before using unfamiliar actions.
3. **Preview.** Resolve targets with `findNotes`/`findCards`, then inspect them with `notesInfo`/`cardsInfo`. Keep note IDs and card IDs distinct.
4. **Confirm.** For modifications, show the proposed changes and target scope/count, then wait for approval. Group related calls under one confirmation.
5. **Back up.** Follow `BACKUP.md` to export all affected existing decks with scheduling, verify the files, and record their paths. A backup is mandatory and does not replace confirmation.
6. **Execute.** Only after backup verification, build JSON with jq; explicitly set `version:6` and the optional top-level `key`. Check `error` before interpreting `result`, including every nested response in a batch.
7. **Verify.** Re-read affected data after writes. After errors or timeouts, inspect state before retrying: changes may have completed or partially applied. Summarize results, failures, relevant IDs, and backup paths.

For example, to tag notes in `deck:French tag:verbs`: search with `findNotes`, preview with `notesInfo`, confirm “Add tag `practice` to these N notes,” back up and verify all decks containing their cards, call `addTags`, and verify the tags.

## Common tasks

| Intent | Action sequence / guidance |
| --- | --- |
| Back up decks | `exportPackage` with `includeSched:true`; verify the `.apkg` before any writes |
| List or create decks | `deckNames` / `createDeck`; confirm creation if part of a note/card modification workflow |
| Search and inspect | `findNotes` → `notesInfo` or `findCards` → `cardsInfo` |
| Add notes | Inspect `modelFieldNames`; preflight with `canAddNotes` or `canAddNotesWithErrorDetail`; confirm, then `addNote` / `addNotes` |
| Edit fields or tags | Confirm, then `updateNoteFields`, `updateNoteTags`, `updateNote`, `addTags`, or `removeTags`; keep the note closed in the browser editor |
| Delete notes | Preview and confirm, then `deleteNotes` |
| Suspend, move, reschedule | Preview and confirm, then `suspend` / `unsuspend`, `changeDeck`, or `setDueDate` |
| Upload/download media | `storeMediaFile` / `retrieveMediaFile`; uploads accept base64 `data`, `path`, or `url` |
| Sync | `sync`; allow a longer timeout |

## Detailed guidance

Read only the sections needed for the task:
- [REFERENCE.md](REFERENCE.md): request/response format, authentication, JSON examples, batching, search syntax, pitfalls, and upstream sources. Read the batching section before using `multi`, and the permissions section for browser-origin access.
- [ACTIONS.md](ACTIONS.md): action catalog and additional confirmation-required examples. Use it for intent mapping, not as a guarantee of installed support or parameter schemas.
- [UPDATE.md](UPDATE.md): instructions for upstream refresh only for when the user explicitly requests to update this skill. This is a documentation-maintenance workflow; do not launch Anki or run collection operations. The audited baseline and source are recorded in [README.md](README.md).
- [BACKUP.md](BACKUP.md): instructions for creating a deck backup before making changes to the deck.
