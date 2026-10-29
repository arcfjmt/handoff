#!/usr/bin/env bash
# git 管理していない親フォルダ（企画中のメモがある）を cwd に作る
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ideas
cat > ideas/habit-app.md <<'MD'
# 習慣トラッカー（企画中）
- iPhone アプリ。月額サブスク
- 1 日 1 回の記録だけに絞る
MD
cp "$here/files/session-transcript.md" .session-transcript.md
mkdir -p .memory && echo "" > .memory/MEMORY.md
