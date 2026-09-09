# AnkiConnect API Reference

## Requests and responses

Send JSON by HTTP POST to the configured endpoint (default `http://127.0.0.1:8765`):

- `action`: action name.
- `version`: explicitly use `6` unless the user specifies otherwise.
- `params`: optional parameter object.
- `key`: configured API key, at the top level, not inside `params`.

Version-6 responses contain `result` and `error`. Always check `error` first; `null` means API success. Successful results may themselves be `null` or `false`, so interpret them according to the action. Omitting `version` defaults to legacy version 4, which can return raw results rather than this envelope.

Use the `version` action for readiness checks rather than relying on GET response text, which differs between builds.

## Permissions and authentication

- Local curl requests without an `Origin` header do not need a CORS permission grant.
- For an untrusted browser origin, call `requestPermission` and check `permission` before proceeding. This action is exempt from API-key authentication and is the only action accepted from an untrusted origin. It may prompt the user and persist their decision; it is not necessarily side-effect-free.
- Do not supply `origin` or `allowed` parameters yourself; the HTTP server supplies them for `requestPermission`.
- A granted response includes `version` and a key-requirement flag. Accept either spelling: `requireApikey` or `requireApiKey`.
- If the add-on's `apiKey` setting is enabled, include the matching top-level `key` in requests, including every nested `multi` action. Never print or commit it.
- Examples use the optional `ANKI_CONNECT_API_KEY` environment variable. Substitute the configured endpoint if it differs from the default; do not broaden bind addresses or CORS permissions to fix connectivity.

## Request examples

These examples use Bash, curl, and jq. Enable `set -o pipefail` so JSON-building and transport failures are not hidden by later pipeline stages. Timeouts shown are for reads; allow longer for imports and sync. Inspect state before retrying any timed-out write.

### List decks

```bash
set -o pipefail
jq -n --arg key "${ANKI_CONNECT_API_KEY:-}" \
  '{action:"deckNames", version:6} +
   (if $key == "" then {} else {key:$key} end)' \
| curl -fsS --max-time 15 http://127.0.0.1:8765 \
    -H 'Content-Type: application/json' -d @-
```

### Search with parameters

```bash
set -o pipefail
jq -n --arg key "${ANKI_CONNECT_API_KEY:-}" \
  --arg query 'deck:French tag:verbs' \
  '{action:"findNotes", version:6, params:{query:$query}} +
   (if $key == "" then {} else {key:$key} end)' \
| curl -fsS --max-time 15 http://127.0.0.1:8765 \
    -H 'Content-Type: application/json' -d @-
```

### Validate responses

Pipe each response above through this filter before using its result. Do **not** add `jq -e`, which rejects successful `null` and `false` results.

```bash
jq 'if type != "object" then error("invalid AnkiConnect response")
    elif (has("result") and has("error") | not) then error("missing response fields")
    elif .error != null then error(.error)
    else .result end'
```

## Batching with `multi`

Use `multi` for independent actions to reduce round-trips. Obtain confirmation once for the scope of any modifying batch before execution. Nested actions do not bypass the confirmation policy.

Every nested action needs its own `version:6` and configured `key`; neither is inherited from the outer request.

```bash
set -o pipefail
jq -n --arg key "${ANKI_CONNECT_API_KEY:-}" \
  '(if $key == "" then {} else {key:$key} end) as $auth |
   {action:"multi", version:6, params:{actions:[
     ({action:"deckNames", version:6} + $auth),
     ({action:"modelNames", version:6} + $auth)
   ]}} + $auth' \
| curl -fsS --max-time 15 http://127.0.0.1:8765 \
    -H 'Content-Type: application/json' -d @-
```

- Actions execute in order, but cannot pass results to later actions. For `findNotes` → `notesInfo`, make separate requests and pass the returned IDs explicitly.
- Batches are **not transactional**. Execution continues after individual action errors and earlier changes are not rolled back. Use separate calls when later actions must stop on failure.
- Check the outer `error`, then every nested response's `error`. Outer success does not imply nested success. The response filter above validates only one envelope, not nested responses.

## Search syntax

Use Anki search syntax for `findNotes` and `findCards`:

- Space-separated terms are ANDed by default; use `or`, parentheses, and `-` for other Boolean logic.
- Filter with `deck:Name`, `tag:tagname`, `note:ModelName`, or `card:CardName`.
- Use field names such as `front:...` to limit searches by field.
- Use `re:` for regex, `w:` for word-boundary searches, and `nc:` to ignore accents.
- Card-state filters include `is:due`, `is:new`, `is:learn`, `is:review`, `is:suspended`, and `is:buried`.
- Use `prop:` for properties such as interval or due date.
- Quote or escape special characters as needed, e.g. `deck:"French Vocabulary" -is:suspended`.

## Modification and environment pitfalls

- On macOS, keep Anki in the foreground or disable App Nap if AnkiConnect pauses.
- Keep a note closed in the browser editor when updating it; otherwise updates may not apply.
- `updateNote` applies fields before tags. If tags fail, fields are not rolled back; if fields fail, tags are not updated. Verify both after errors.
- `importPackage` paths are relative to Anki's `collection.media` folder, not the client working directory.
- `deleteDecks` requires `cardsToo:true`; it does not support retaining the cards. Preview affected cards and confirm their deletion explicitly.
- Media uploads via `storeMediaFile` accept base64 `data`, a file `path`, or a `url`. Confirm deletion or overwrites that affect existing notes/cards.

## Upstream sources

Installed builds may expose different actions and behavior despite sharing an API version. Discover action names with `apiReflect` (`scopes:["actions"]`); consult documentation or implementation for exact parameter schemas.

- [Upstream documentation](https://git.sr.ht/~foosoft/anki-connect)
- [API implementation](https://git.sr.ht/~foosoft/anki-connect/tree/master/item/plugin/__init__.py)
- [HTTP implementation](https://git.sr.ht/~foosoft/anki-connect/tree/master/item/plugin/web.py)
- [Anki search syntax](https://docs.ankiweb.net/searching.html)
