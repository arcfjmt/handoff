#!/usr/bin/env bash
# 機能が完成済み（worktree 上・最後の 1 変更だけ未コミット）で、古い引き継ぎメモが残るリポジトリを cwd に作る
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
git init -q -b main .
git config user.name "Test User"; git config user.email "test@example.com"
exclude="$(git rev-parse --git-path info/exclude)"
printf '.worktrees/\n.session-transcript.md\n.memory/\n.handoff/\n.origin.git/\n' >> "$exclude"
mkdir -p tasklog tests docs/worklog
cat > CLAUDE.md <<'MD'
# tasklog
タスクを JSON ファイルに保存する小さな Python CLI。

## git
- コミット・マージ・プッシュはユーザーの確認なしで行ってよい
- マージ・プッシュの前に `git fetch` し、`python3 -m unittest discover -s tests` が通ることを確かめる
- 作業ブランチは main にマージしたら削除し、worktree も片付ける

## 作業記録
作業ごとに `docs/worklog/YYYY-MM-DD-<トピック>.md` に記録を書き、作業の変更と同じコミットに含める。
MD
cat > README.md <<'MD'
# tasklog
タスクを JSON に保存する CLI。
MD
touch tasklog/__init__.py tests/__init__.py
cat > tasklog/storage.py <<'PY'
def add(tasks, title, due=None):
    task = {"id": len(tasks) + 1, "title": title, "done": False, "due": due}
    tasks.append(task)
    return task
PY
git add -A; git commit -qm "初期実装"
git init -q --bare .origin.git
git remote add origin "$PWD/.origin.git"
git push -q -u origin main
git worktree add -q -b feat/export .worktrees/export
WT=.worktrees/export
cat > $WT/tasklog/export.py <<'PY'
import csv


def to_csv(tasks, out):
    w = csv.writer(out)
    w.writerow(["id", "title", "done", "due"])
    for t in tasks:
        w.writerow([t["id"], t["title"], t["done"], t.get("due") or ""])
PY
cat > $WT/tests/test_export.py <<'PY'
import io
import unittest
from tasklog import export, storage


class ExportTest(unittest.TestCase):
    def test_to_csv(self):
        tasks = []
        storage.add(tasks, "a", due="2026-11-01")
        out = io.StringIO()
        export.to_csv(tasks, out)
        self.assertEqual(out.getvalue().splitlines()[1], "1,a,False,2026-11-01")


if __name__ == "__main__":
    unittest.main()
PY
git -C $WT add -A; git -C $WT commit -qm "CSV エクスポートを追加"
# 最後の変更（README の使い方追記）だけ未コミット
printf '\n## エクスポート\n`tasklog.export.to_csv(tasks, out)` で CSV を書き出す（列: id, title, done, due）。\n' >> $WT/README.md
# 前のセッションが残した古い引き継ぎメモ
mkdir -p .handoff
cat > .handoff/HANDOFF.md <<'MD'
# 引き継ぎメモ

- 作成: 2026-10-28 18:10
- ブランチ / HEAD: feat/export（worktree .worktrees/export）
- 中断の理由: コンテキスト量

## 目的
CSV エクスポート機能を追加する

## 次にやること
1. .worktrees/export で tasklog/export.py の to_csv を実装する
2. tests/test_export.py を unittest で書く
3. README に使い方を書き、main にマージする

## 保留中の判断
なし
MD
cp "$here/files/session-transcript.md" .session-transcript.md
mkdir -p .memory && echo "" > .memory/MEMORY.md
