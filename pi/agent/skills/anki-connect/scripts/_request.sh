# Shared transport for the read-only helpers; params are a JSON object on stdin.
anki_request() {
  jq -c --arg action "$1" '
    {action:$action, version:6, params:.} +
    (if (env.ANKI_CONNECT_API_KEY // "") == "" then {}
     else {key:env.ANKI_CONNECT_API_KEY} end)' |
    curl -fsS --connect-timeout 5 --max-time 30 \
      "${ANKI_CONNECT_URL:-http://127.0.0.1:8765}" \
      -H 'Content-Type: application/json' --data-binary @- |
    jq -cs '
      if length != 1 then error("expected one AnkiConnect response")
      else .[0] |
        if type != "object" then error("invalid AnkiConnect response")
        elif (has("result") and has("error") | not) then error("missing response fields")
        elif .error != null then error(.error)
        else .result end
      end'
}
