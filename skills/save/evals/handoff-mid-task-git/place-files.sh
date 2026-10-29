#!/usr/bin/env bash
# 作業途中の git リポジトリ（未コミットの変更・worktree・作業記録の規則あり）を cwd に作る
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
git init -q -b main .
git config user.name "Test User"; git config user.email "test@example.com"
mkdir -p tasklog tests docs/worklog
cat > CLAUDE.md <<'MD'
# tasklog
タスクを JSON ファイルに保存する小さな Python CLI。

## 作業記録
作業ごとに `docs/worklog/YYYY-MM-DD-<トピック>.md` に記録を書き、作業の変更と同じコミットに含める。
内容: やったこと・決定と理由・学び。
MD
cat > tasklog/__init__.py <<'PY'
PY
cat > tasklog/storage.py <<'PY'
import json
from pathlib import Path


def load(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return json.loads(path.read_text())


def save(path: Path, tasks: list[dict]) -> None:
    path.write_text(json.dumps(tasks, ensure_ascii=False, indent=2))


def add(tasks: list[dict], title: str) -> dict:
    task = {"id": len(tasks) + 1, "title": title, "done": False}
    tasks.append(task)
    return task
PY
cat > tests/test_storage.py <<'PY'
import unittest
from tasklog import storage


class AddTest(unittest.TestCase):
    def test_add(self):
        tasks = []
        t = storage.add(tasks, "a")
        self.assertEqual(t["id"], 1)


if __name__ == "__main__":
    unittest.main()
PY
git add -A; git commit -qm "初期実装: タスクの追加と保存"
# export 用の worktree（途中）
git worktree add -q -b feat/export .worktrees/export
echo '.worktrees/' >> "$(git rev-parse --git-path info/exclude)"
cat > .worktrees/export/tasklog/export.py <<'PY'
import csv


def to_csv(tasks, out):
    w = csv.writer(out)
    w.writerow(["id", "title", "done"])
    # TODO: due 列を追加する（main の期限日対応が入ってから）
    for t in tasks:
        w.writerow([t["id"], t["title"], t["done"]])
PY
# main 側の未コミット変更（期限日対応）
cat > tasklog/storage.py <<'PY'
import json
from datetime import date
from pathlib import Path


def load(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return json.loads(path.read_text())


def save(path: Path, tasks: list[dict]) -> None:
    path.write_text(json.dumps(tasks, ensure_ascii=False, indent=2))


def add(tasks: list[dict], title: str, due: str | None = None) -> dict:
    if due is not None:
        date.fromisoformat(due)  # ISO 形式 (YYYY-MM-DD) 以外は ValueError
    task = {"id": len(tasks) + 1, "title": title, "done": False, "due": due}
    tasks.append(task)
    return task


def overdue(tasks: list[dict], today: date) -> list[dict]:
    return [t for t in tasks if t.get("due") and not t["done"] and date.fromisoformat(t["due"]) < today]
PY
cat > tests/test_due.py <<'PY'
import unittest
from datetime import date
from tasklog import storage


class DueTest(unittest.TestCase):
    def test_add_with_due(self):
        tasks = []
        t = storage.add(tasks, "a", due="2026-11-01")
        self.assertEqual(t["due"], "2026-11-01")

    def test_invalid_due(self):
        with self.assertRaises(ValueError):
            storage.add([], "a", due="11/01")

    def test_overdue(self):
        tasks = []
        storage.add(tasks, "a", due="2026-10-01")
        storage.add(tasks, "b", due="2026-12-01")
        self.assertEqual([t["title"] for t in storage.overdue(tasks, date(2026, 10, 29))], ["a"])


if __name__ == "__main__":
    unittest.main()
PY
cp "$here/files/session-transcript.md" .session-transcript.md
echo '.session-transcript.md' >> "$(git rev-parse --git-path info/exclude)"
mkdir -p .memory && echo "" > .memory/MEMORY.md
echo '.memory/' >> "$(git rev-parse --git-path info/exclude)"
