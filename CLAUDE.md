# daily-brief リポジトリ運用ルール

このリポジトリは Claude Code の **Routine（クラウド実行）** から自動更新される。
毎回の実行で「レポートHTMLの生成 → main へ push → LINE通知」を行う。

## 絶対に守ること

1. **公開情報のみを扱う。** このリポジトリと GitHub Pages は public。顧客名・売上・未公開ロードマップ・
   個人情報・社内固有名詞は一切書かない。判断に迷う情報は載せずに省く。
2. **シークレットをコミットしない。** トークンは Routine の環境変数から読む。
   `LINE_CHANNEL_ACCESS_TOKEN` / `LINE_TO_USER_ID` をファイルに書き出してはいけない。
3. **LINE送信は必ず `scripts/notify_line.sh` 経由。** curl を直接書かない
   （リトライキー・文字数丸め・エラーハンドリングがスクリプト側に入っている）。
4. **push 先は `main` を第一候補、失敗したら `claude/brief-<YYYY-MM-DD>`。**
   Pages は `main` / `docs` を配信している。Routine は `claude/` プレフィックス以外の
   ブランチへ push できない場合があるため、拒否されたら日付付きの `claude/brief-*` に push する。
   `.github/workflows/sync-docs-to-main.yml` が docs/ を main へ同期する。

## ファイル構成

| パス | 役割 |
|---|---|
| `docs/index.html` | 最新レポート。**これが固定の公開URL**。毎回上書きする |
| `docs/archive/YYYY-MM-DD.html` | 当日分のスナップショット。追加のみ |
| `scripts/notify_line.sh` | LINE push（第1引数が本文） |
| `scripts/check_quota.sh` | 無料枠残量の確認 |
| `.github/workflows/sync-docs-to-main.yml` | `claude/**` に push された docs/ を main へ同期（触らない） |

## docs/index.html の要件

- **単一ファイル完結。** CSS も JS も inline。外部CDN・外部フォント・外部画像を参照しない
  （オフラインでも壊れないこと、追跡を混ぜないこと）
- `<meta name="viewport" content="width=device-width, initial-scale=1">` 必須。
  **スマホのLINE内ブラウザで読むことが主用途**なので、1カラム・本文16px以上・横スクロールなし
- 先頭に更新日時（JST）を表示
- 末尾に `docs/archive/` への直近7件のリンク一覧
- `prefers-color-scheme` でダーク/ライト両対応

## デザイントークン

- Colors: bg `#ffffff` / surface `#f6f7f9` / text `#14181f` / muted `#5b6472` / border `#e3e6ea` / accent `#1a4d8f` / warn `#b45309`
- Dark: bg `#0e1117` / surface `#161b22` / text `#e6edf3` / muted `#8b949e` / border `#262c36` / accent `#6aa3e0`
- Typography: system-ui, "Hiragino Sans", "Noto Sans JP", sans-serif。本文 16px / 行間 1.75
- Spacing: 8px スケール / border-radius 8px
- 影は使わない。区切りは border のみ

## LINE通知本文の要件

- **900文字以内**。スマホの通知プレビューで要点が読めること
- 構成：1行目にタイトルと日付 → 空行 → 要点を「・」で3〜5個 → 空行 → 最後の行に公開URL
- URLは末尾に単独で置く（LINEが自動リンク化する）
- Markdown記法は使わない（LINEはプレーンテキスト表示。`**`や`#`がそのまま見える）

## 変更してはいけないファイル

- `scripts/` 配下
- `.github/workflows/` 配下
- `CLAUDE.md`, `README.md`, `ROUTINE_PROMPT.md`
