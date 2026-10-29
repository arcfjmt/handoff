#!/usr/bin/env bash
# 引き継ぎメモを書いた後に、別の作業ラインのコミットが 1 つ入ったリポジトリを cwd に作る
set -eu
git init -q -b main .
git config user.name "Test User"; git config user.email "test@example.com"
mkdir -p tasklog tests
printf 'import json\n\n\ndef add(tasks, title, due=None):\n    task = {"id": len(tasks) + 1, "title": title, "done": False, "due": due}\n    tasks.append(task)\n    return task\n' > tasklog/storage.py
touch tasklog/__init__.py
git add -A; git commit -qm "期限日対応を追加"
head=$(git rev-parse --short HEAD)
exclude="$(git rev-parse --git-path info/exclude)"
echo '.handoff/' >> "$exclude"
mkdir -p .handoff
cat > .handoff/HANDOFF.md <<MD
# 引き継ぎメモ

- 作成: 2026-10-29 15:40
- 作業フォルダ: (このリポジトリ)
- ブランチ / HEAD: main / ${head}（期限日対応を追加）
- 中断の理由: コンテキスト量

## 目的
tasklog にタスクの期限日と CSV エクスポートを付ける（ユーザーの依頼:「タスクに期限日を付けられるようにして。CSV エクスポートも欲しい」）

## 完了したこと
- storage.add に due 引数を追加（${head}）

## 次にやること
1. tasklog/cli.py を新規作成し、\`add\` サブコマンドに \`--due YYYY-MM-DD\` オプションを付ける（argparse、標準ライブラリのみ）
2. \`list\` サブコマンドで期限切れタスクに印を付ける（見た目は保留中の判断を待つ）
3. CSV エクスポート（未着手）

## 保留中の判断
- 期限切れの表示を赤字にするか（ユーザーが検討中）。2 の見た目部分はこれ待ち

## 重要な文脈
- 外部ライブラリは使わない（ユーザーの指示）。テストは unittest
- 期限日は ISO 文字列で保存（JSON にそのまま書けるため）

## 作業場所の状態
- worktree なし。未コミットの変更なし
- テスト: なし（tests/ は空）

## 参照ファイル
- tasklog/storage.py
MD
# メモ作成後に、別の作業ラインが cli.py を作ってコミットした
printf 'import argparse\n\n\ndef main():\n    p = argparse.ArgumentParser(prog="tasklog")\n    sub = p.add_subparsers(dest="cmd")\n    sub.add_parser("add").add_argument("title")\n    p.parse_args()\n' > tasklog/cli.py
git add tasklog/cli.py
GIT_AUTHOR_NAME="Teammate" GIT_AUTHOR_EMAIL="mate@example.com" git commit -qm "CLI の骨組みを追加"
