#!/usr/bin/env bash
# LINE Messaging API push 通知
# usage: scripts/notify_line.sh "<本文>"
# 必要な環境変数: LINE_CHANNEL_ACCESS_TOKEN, LINE_TO_USER_ID
set -euo pipefail

: "${LINE_CHANNEL_ACCESS_TOKEN:?LINE_CHANNEL_ACCESS_TOKEN is not set}"
: "${LINE_TO_USER_ID:?LINE_TO_USER_ID is not set}"

TEXT="${1:-}"
if [ -z "$TEXT" ]; then
  echo "usage: $0 \"<message text>\"" >&2
  exit 2
fi

RESP="$(mktemp)"
trap 'rm -f "$RESP"' EXIT

# text message は 5000 文字上限。安全側で 4900 に丸める
BODY="$(TEXT="$TEXT" TO="$LINE_TO_USER_ID" python3 - <<'PY'
import json, os
text = os.environ["TEXT"][:4900]
print(json.dumps(
    {"to": os.environ["TO"], "messages": [{"type": "text", "text": text}]},
    ensure_ascii=False,
))
PY
)"

RETRY_KEY="$(python3 -c 'import uuid; print(uuid.uuid4())')"

HTTP="$(curl -sS -o "$RESP" -w '%{http_code}' \
  --max-time 20 --retry 2 --retry-connrefused \
  -X POST https://api.line.me/v2/bot/message/push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}" \
  -H "X-Line-Retry-Key: ${RETRY_KEY}" \
  --data-binary "$BODY")"

if [ "$HTTP" != "200" ]; then
  echo "ERROR: LINE push failed (HTTP ${HTTP})" >&2
  cat "$RESP" >&2
  echo >&2
  case "$HTTP" in
    401) echo "HINT: LINE_CHANNEL_ACCESS_TOKEN が無効/失効" >&2 ;;
    403) echo "HINT: api.line.me が環境の Allowed domains に未登録の可能性 (x-deny-reason を確認)" >&2 ;;
    400) echo "HINT: LINE_TO_USER_ID が不正、または本文が空/長すぎる" >&2 ;;
    429) echo "HINT: 月間メッセージ上限に到達" >&2 ;;
  esac
  exit 1
fi

echo "OK: LINE push sent (${#TEXT} chars)"
