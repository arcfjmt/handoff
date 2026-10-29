---
name: resume
description: Read the handoff note (.handoff/HANDOFF.md) that a previous session left with handoff:save, check it against the current state of the repository, confirm the next piece of work with the user, and then resume the paused work. Always use this skill when the user runs /handoff:resume or asks to read the handoff note, continue from last time, or pick up where the previous session left off — even if they don't name the skill. Japanese phrasings count too, e.g. 「引き継ぎメモを読んで」「前回の続きから」「中断したところから再開」. Also use it when, at the start of a new session, you notice a .handoff/HANDOFF.md in the working folder, to ask the user whether to resume.
---

# handoff:resume — pick the work back up from the handoff note

The Claude in the previous session moved what existed only in its conversation into `.handoff/HANDOFF.md`. This skill reads that note and **checks that the state it describes matches the actual state before** continuing. The note records one moment in time; since then the user may have changed things by hand, or another line of work may have merged. Following the note without noticing a mismatch can overwrite someone else's changes or redo work that is already finished.

Write every message to the user in the language the user is using (or, before they have written anything, the language of the note).

## Steps

### 1. Read the note

Read `.handoff/HANDOFF.md` in the folder this session was started in.

- If it isn't there, check `.handoff/archive/` for recent notes, tell the user that no handoff note was found along with any candidates you found, and stop. Don't start work on a guess
- If the note is old (several days or more), tell the user

### 2. Check the state

Compare the note's "Branch / HEAD" and "State of the workspace" with the current state.

```bash
git branch --show-current
git log --oneline -5
git status --short
git worktree list
```

- If HEAD has moved past the note, look at the new commits (someone may have continued the work)
- If there are uncommitted changes, check whether the note accounts for them
- Check that the worktrees and branches in the note exist
- If there is a mismatch you can't explain, report it to the user and ask for their call before starting any work

### 3. Read the files you need

Of the note's "Files to read", read the ones needed for the next step. If there is a plan document, focus on the part for the task being resumed. There is no need to load everything (the session was switched to free up context; don't use it all up here).

### 4. Confirm with the user, then continue

Give a short summary:

- The goal, and how much is done
- The next step you will start with (what, in which files, with which commands)
- Pending decisions, if any
- Any mismatch found while checking the state

Then always ask whether to resume with this work, and **don't start until the user confirms** (no file changes, commits, or subagents before that). The note was written by the previous session's Claude; it may be out of step with what the user intends, or priorities may have changed during the break, so have the user look it over themselves before resuming. If the user asks for different work or a different order, follow that.

### 5. Clear the note away

Once the user has confirmed and you have started work, move the note you used to `.handoff/archive/<the note's creation time, YYYY-MM-DD-HHMM>.md`. Leaving `HANDOFF.md` in place would let a later session read an old note as if it were the latest.
