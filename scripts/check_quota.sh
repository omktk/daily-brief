#!/usr/bin/env bash
# 今月の送信可能数と消費数を確認（無料枠 200通/月 の残量チェック）
set -euo pipefail
: "${LINE_CHANNEL_ACCESS_TOKEN:?}"
H="Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}"
echo "--- quota ---"
curl -sS --max-time 15 -H "$H" https://api.line.me/v2/bot/message/quota; echo
echo "--- consumption ---"
curl -sS --max-time 15 -H "$H" https://api.line.me/v2/bot/message/quota/consumption; echo
