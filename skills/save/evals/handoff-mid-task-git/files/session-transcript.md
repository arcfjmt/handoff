# これまでの会話（このセッションの記録）

**ユーザー**: tasklog にタスクの期限日を付けられるようにして。あと CSV でエクスポートする機能も欲しい。

**Claude**: 期限日対応を main で、CSV エクスポートを worktree `.worktrees/export`（ブランチ feat/export）で並行して進めます。

**Claude**: 期限日の解析に python-dateutil を使おうとしました。

**ユーザー**: 外部ライブラリは入れないで。このプロジェクトは標準ライブラリだけでやりたい。今後もずっとそうしてほしい。

**Claude**: 了解しました。dateutil はやめ、`date.fromisoformat` で ISO 形式（YYYY-MM-DD）だけを受け付けます。期限日は JSON に保存するので、datetime オブジェクトではなく文字列のまま持つことにしました（JSON にそのまま書けるため）。

**ユーザー**: テストは pytest じゃなくて unittest で書いてね。

**Claude**: storage.add に due 引数と overdue() を追加し、tests/test_due.py を書きました。`python -m unittest` で 4 件すべて通っています。（まだコミットしていません）

**Claude**: export 側は to_csv の骨組みまで書きました。due 列は main の期限日対応がマージされてから追加する予定です（未コミット）。

**Claude**: 次は CLI（tasklog/cli.py はまだ存在しない）に `--due` オプションを追加し、`list` コマンドで期限切れを目立たせる予定です。

**ユーザー**: 期限切れの表示を赤字にするかどうかは、ちょっと考えさせて。後で答えます。

**Claude**: 了解しました。その判断が出るまで、期限切れ表示の見た目の部分は保留にします。
