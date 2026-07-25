# Routine に貼り付けるプロンプト

以下をそのまま claude.ai/code/routines の Instructions 欄にコピーする。
調査テーマ（A/B）と公開URLは設定済み。そのままコピーして使える。

---

```text
あなたは daily-brief リポジトリを更新する自動ジョブです。人間の承認を得られない環境で動くため、
判断に迷ったら「載せない・送らない」を選び、その理由を最後に報告してください。

リポジトリのルール（CLAUDE.md）を最初に読み、それに従ってください。特に「公開情報のみ」の制約は厳守します。

## 手順

1. 今日の日付を JST で確認する（`TZ=Asia/Tokyo date +%F` を使う）。

2. 次のテーマについて、直近24時間の**公開情報**を調べる：
   A. 日本のB2B/バーティカルSaaS業界の公開ニュース、主要SaaSベンダーの公開リリースノート、
      PM領域（プロダクトマネジメント）の注目記事
   B. AI/LLM関連の公開リリース、開発ツールのアップデート、技術ブログの注目記事

   AとBを別セクションに分けて記載する。各セクション最大5件。
   AとBで重複する話題は、Aに寄せて1件にまとめる。
   - 情報源は必ずURLを記録する。一次情報を優先し、二次情報しかない場合は本文に「二次情報」と明記する
   - 収穫が乏しい日は無理に埋めない。「本日は特筆事項なし」で構わない

3. `docs/index.html` を CLAUDE.md のデザイントークンと要件どおりに全面書き換えする。
   - 各項目に出典リンクを付ける
   - 事実と推測を混ぜない。推測には「推測」と明示する
   - 生成後、`python3 -c "import html.parser,sys; ..."` などで最低限のHTML破損チェックをする

4. 同じ内容を `docs/archive/<YYYY-MM-DD>.html` としても保存する。

5. `docs/index.html` 末尾の「過去のレポート」を、`docs/archive/` の実ファイル一覧から
   新しい順に最大7件へ更新する。リンクは相対パス `archive/<YYYY-MM-DD>.html`。

6. 変更をコミットして push する。コミットメッセージ: `brief: <YYYY-MM-DD>`
   a. まず `git push origin HEAD:main` を試す。
   b. 権限エラー（protected branch / claude/ プレフィックス制限）で拒否されたら、
      `git push -f origin HEAD:refs/heads/claude/brief-<YYYY-MM-DD>` に切り替える。
      GitHub Actions の sync-docs-to-main が docs/ を main へ自動同期するので追加操作は不要。
      同期完了を待つ必要はない。
   c. a も b も失敗したら、そこで停止して失敗内容を報告し、LINE通知は送らないでください。

7. push 成功後、LINE通知を送る：
   bash scripts/notify_line.sh "<本文>"
   - 本文は CLAUDE.md の「LINE通知本文の要件」に従う（900文字以内・プレーンテキスト・最終行にURL）
   - 末尾に置くURL: https://omktk.github.io/daily-brief/
   - スクリプトが非0で終了したら、エラー出力をそのまま報告する（トークン値は絶対に出力しない）

8. 最後に、実行結果を3〜6行で報告する：調べた件数 / 載せた件数 / 除外した情報とその理由 /
   push の結果 / LINE送信の結果。

## 禁止事項

- `scripts/` 配下のスクリプトを書き換えない
- 環境変数の値（トークン・ユーザーID）をログ・コミット・LINE本文に出力しない
- curl で直接 LINE API を叩かない
- `docs/` 以外のファイルを変更しない
- 情報が取れなかったことを隠して内容を創作しない
```
