# Routine → GitHub Pages → LINE 通知（セットアップ手順）

PCの電源に依存せず、Claude Code の Routine（Anthropic のクラウドで実行）が毎日レポートHTMLを生成し、
GitHub Pages の固定URLに公開し、LINEに要約とURLを push する構成。

```
Routine（クラウド・毎日定時）
  ├─ 公開情報を調査
  ├─ docs/index.html を生成 → main に push
  ├─ GitHub Pages が固定URLで配信
  └─ scripts/notify_line.sh で LINE に要約＋URLを push
```

---

## 前提条件

| 項目 | 必要なもの |
|---|---|
| Claude プラン | Pro / Max / Team / Enterprise（Routines は research preview） |
| Claude Code on the web | 有効化済み |
| 認証 | claude.ai アカウントログイン。**APIキー・Bedrock・Vertex では Routine が使えない** |
| GitHub | アカウント（public リポジトリを1つ作る） |
| LINE | LINE公式アカウント＋Messaging APIチャネル |

---

## Step 1. GitHubリポジトリを作る

1. `daily-brief` という名前で **public** リポジトリを作成（Pages を無料で使うため）
2. このフォルダの中身をそのまま push

```bash
git init
git add .
git commit -m "init: routine + pages + line notify"
git branch -M main
git remote add origin https://github.com/<ユーザー名>/daily-brief.git
git push -u origin main
```

3. リポジトリの **Settings → Pages** で
   - Source: `Deploy from a branch`
   - Branch: `main` / フォルダ: `/docs`
   - Save

数分後に `https://<ユーザー名>.github.io/daily-brief/` が開けば成功。プレースホルダーページが見える。

> このURLは誰でも閲覧できる。**公開情報のみを載せる**前提の構成。

---

## Step 2. LINE側を用意する

1. [LINE Developers Console](https://developers.line.biz/console/) でプロバイダーを作成
2. **Messaging API チャネル**を新規作成（LINE公式アカウントが同時に作られる）
3. **Messaging API 設定**タブ → 「チャネルアクセストークン（長期）」を発行してコピー
   → これが `LINE_CHANNEL_ACCESS_TOKEN`
4. **チャネル基本設定**タブ → 「あなたのユーザーID」をコピー
   → これが `LINE_TO_USER_ID`（`U` で始まる33文字。**APIでは取得できず、ここでしか見られない**）
5. 同じ「Messaging API 設定」タブのQRコードを自分のLINEで読み取り、**友だち追加**
   （友だちでないユーザーには push できない）
6. LINE Official Account Manager の設定で「応答メッセージ」をオフにしておく（自動返信が邪魔なため）

### 送信枠

コミュニケーションプラン（¥0）は **月200通**。1日1通なら月30通で収まる。残量確認：

```bash
LINE_CHANNEL_ACCESS_TOKEN=xxx bash scripts/check_quota.sh
```

---

## Step 3. Routine 用のクラウド環境を作る

**ここが一番ハマるポイント。** デフォルト環境は許可ドメインの allowlist 方式で、`api.line.me` は
含まれていない。そのまま実行すると `403 x-deny-reason: host_not_allowed` で LINE 送信が失敗する。

1. [claude.ai/code/routines](https://claude.ai/code/routines) → **New routine**
2. Instructions 欄の下にある環境セレクタ（雲アイコン `Default`）を開く
3. 環境にホバーして歯車アイコン → **Update cloud environment**
4. **Network access** を `Custom` に変更
   - Allowed domains に **`api.line.me`** を追加
   - 「Also include default list of common package managers」を**チェックしたまま**にする
5. **Environment variables** に登録
   | 変数名 | 値 |
   |---|---|
   | `LINE_CHANNEL_ACCESS_TOKEN` | Step 2-3 のトークン |
   | `LINE_TO_USER_ID` | Step 2-4 のユーザーID |
6. Save changes

> Network access を `Full` にしても動くが、自動実行のジョブに無制限の外向き通信を与える必要はない。
> `Custom` + `api.line.me` に絞る。

---

## Step 4. Routine を作る

1. **Name**: `daily-brief`
2. **Instructions**: `ROUTINE_PROMPT.md` の内容をコピーし、`【ここを差し替え】` 2箇所を埋める
3. **Repositories**: `daily-brief` を選択
4. **Environment**: Step 3 で作った環境
5. **Permissions** → **Allow unrestricted branch pushes** があれば `daily-brief` に対して ON。
   **この設定がUIに無い場合がある**（research preview のUI差分）。無い場合は Step 5 の
   ワークフローが保険として機能するので、そのまま進めてよい
6. **Connectors**: このRoutineでは不要。**全部外す**（不要な書き込み権限を渡さない）
7. **Trigger**: Schedule → Daily → 好きな時刻（例 07:00）
   - 最小間隔は1時間。スケジュールにはstaggerがあり数分ずれる
8. **Create**

---

## Step 5. main への push 制限の保険（ワークフロー）

Routine はデフォルトで `claude/` プレフィックスのブランチにしか push できない。
Routine の編集UIに **Allow unrestricted branch pushes** が見つからない場合、
`main` への直接 push が拒否され Pages が更新されない。

そのため `.github/workflows/sync-docs-to-main.yml` を同梱している。

- `claude/**` ブランチに `docs/` の変更が push されると発火し、`docs/` を `main` へ同期する
- `main` へ直接 push できた場合は発火しない（無害）
- Routine のプロンプトは「まず main、拒否されたら `claude/brief-<日付>`」の順で試すよう書いてある

### 確認ポイント：Workflow permissions

このリポジトリの現在の設定は **「Read repository contents and packages permissions」（read-only）**。

ワークフロー側で `permissions: contents: write` を明示しているため、これで動く可能性が高いが、
**リポジトリ既定が read-only の場合に YAML 側の宣言で write に昇格できるかは要検証**（推測）。

初回実行後に Actions タブでワークフローが `403` で失敗していたら、
**Settings → Actions → General → Workflow permissions** を
**Read and write permissions** に変更する。

> この変更は GITHUB_TOKEN にリポジトリ全体の書き込み権限を与える。このリポジトリには
> 同梱ワークフロー1本しか無く、public リポジトリの fork からの PR では token は read-only に
> 落ちるため実務上のリスクは小さいが、必要になってから変更する方針にしている。

## Step 6. 動作確認

Routine の詳細ページで **Run now**。実行後の確認順序：

1. **セッションのトランスクリプトを開いて中身を読む。**
   実行リストの緑ステータスは「セッションが落ちなかった」だけの意味で、
   タスクの成功を意味しない。ネットワーク遮断やpush失敗はトランスクリプト内にしか出ない
2. GitHub のコミット履歴に `brief: YYYY-MM-DD` が入ったか
3. Pages のURLが更新されたか（反映に数分かかる）
4. LINEに通知が届いたか

### トラブルシュート

| 症状 | 原因 |
|---|---|
| `403` / `host_not_allowed` | Step 3-4 の Allowed domains に `api.line.me` が入っていない |
| `401` | チャネルアクセストークンが無効。再発行して環境変数を更新 |
| `400` | `LINE_TO_USER_ID` が誤り、または友だち追加していない |
| `429` | 月200通の上限。`check_quota.sh` で確認 |
| push が `claude/xxx` ブランチに入る | Step 4-5 の Allow unrestricted branch pushes が OFF |
| Pages が404 | Settings → Pages の Branch/フォルダ設定が `main` / `/docs` になっていない |
| ワークフローが `403` で失敗 | Settings → Actions → General → Workflow permissions が read-only |
| `claude/brief-*` にコミットはあるが main が古い | ワークフローの実行ログ（Actions タブ）を確認 |
| `/schedule` が Unknown command | `ANTHROPIC_API_KEY` 等が設定されている。Web UIから作る |

---

## 運用上の注意

- **1日あたりのRoutine実行回数に上限**があり、通常のサブスク使用量も消費する。
  使用状況は [claude.ai/settings/usage](https://claude.ai/settings/usage) で確認
- Routine は**自分の個人アカウントに属する**。GitHubコミットもコネクタ操作も自分の名前で記録される
- Routine は承認プロンプトなしで自律実行される。プロンプトの禁止事項リストが唯一のガードレール
- research preview なので仕様変更あり。動かなくなったら公式ドキュメントを確認

## 参照

- [Automate work with routines](https://code.claude.com/docs/en/routines)
- [Cloud environment / Network access](https://code.claude.com/docs/en/claude-code-on-the-web#network-access)
- [LINE Messaging API リファレンス](https://developers.line.biz/ja/reference/messaging-api/#send-push-message)
