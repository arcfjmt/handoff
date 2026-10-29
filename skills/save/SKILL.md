---
name: save
description: Pause work at a clean stopping point and get ready to continue in a fresh session — commit changes, write the work log, update memory, and leave a handoff note in .handoff/HANDOFF.md. If no work is left to hand over, wrap the task up instead (verify, commit, integrate, work log, memory). Always use this skill when the user wants to hand off, switch or restart sessions, says the context is getting large or full, wants to stop here before /clear, or wants to restart to load new skills, plugins or settings — even if they don't name the skill. Japanese phrasings count too, e.g. 「引き継ぎ」「ハンドオフ」「セッションを切り替えたい」「新しいセッションに移りたい」「コンテキストが増えてきた」「一度区切って」. Also use it to suggest a handoff when you notice the context window is running low. The counterpart for picking the work back up is handoff:resume.
---

# handoff:save — pause work and hand it to the next session

The Claude in the next session remembers nothing of this conversation. All it will have is the state of the repository (commits and files), the project's CLAUDE.md, auto-memory, and the handoff note this skill writes. So the point of this skill is to **move everything that exists only in the conversation into places the next Claude can read**. Above all, keep the things that cannot be recovered from the code: why things were done, what was tried and failed, and instructions the user gave in conversation.

This skill is often called when little context is left. Don't reread large files or widen the investigation; write up what the conversation already holds, quickly.

Write the handoff note and every message to the user in the language the user has been using in this session.

## Steps

### 0. Decide whether there is work to hand over

First, check whether this session's work is finished.

- **Nothing to hand over**: every request from the user is done, and there is no next step and no decision waiting on the user. Follow "When there is nothing to hand over" below to wrap the task up. Don't write a handoff note (an empty note would make the next session try to resume finished work)
- **Work to hand over**: there is remaining work or at least one pending decision. Continue from step 1
- If unsure, treat it as work to hand over. An extra note does little harm; dropped work goes unnoticed in the next session

### 1. Find a stopping point

- Don't start new tasks. If the step in progress will be done in a few minutes, finish it. If not, get back to a state that isn't broken (sometimes it is better not to commit a half-done edit and record it in the note as in progress)
- If subagents or background jobs are running, wait for them to finish and collect their results — once the session closes, their results can no longer be received. If something will take very long (tens of minutes or more), ask the user whether to wait or stop it and record it. If you stop it, write in the note what it was doing and how far it got
- Don't force decisions that are the user's to make. Put them under "Pending decisions" in the note

### 2. Commit changes

Uncommitted local changes leave the next session unable to tell who changed what and why. Commit following the git rules in the project's CLAUDE.md.

- Check `git status` in the main working tree and in every worktree in use (`git worktree list`)
- Unfinished work may be committed with a message that marks it as WIP (e.g. `wip: <topic>, partway (for handoff)`)
- Push or merge only where you would in normal work. Don't put unfinished work into the merge target just for the handoff
- If you commit while tests are failing, say so in the note
- If the folder isn't under git, skip this step

### 3. Write the work log (if the project has a rule for it)

If the project's CLAUDE.md has a rule for work logs (e.g. `docs/worklog/`), write this session's entry following it and include it in the commit. If there is no rule, don't write one (the handoff note is enough).

A work log keeps "lessons for future development"; the handoff note keeps "the state the next session needs to start right away". They serve different purposes. Don't write the same content at length in both; the note can just point to the log file.

### 4. Update memory

Save to auto-memory what you learned in this session that **will stay useful after this task is over**: the user's preferences and instructions, circumstances of the project, pitfalls likely to bite again. Check for an existing memory that covers it and update that instead of duplicating.

Don't put information that only matters during this task — how far you got, what comes next — into memory. That belongs in the handoff note.

### 5. Write the handoff note

Save it as `.handoff/HANDOFF.md` in **the folder this session was started in** (the primary working directory). The next session is assumed to start in the same folder.

- If a `HANDOFF.md` already exists, move it to `.handoff/archive/<YYYY-MM-DD-HHMM>.md` before writing the new one
- In a git repository, keep `.handoff/` out of git. Changing `.gitignore` would need a commit, so use `info/exclude`, which affects nothing outside this clone:

```bash
exclude="$(git rev-parse --git-path info/exclude)"
grep -qxF '.handoff/' "$exclude" 2>/dev/null || echo '.handoff/' >> "$exclude"
```

Write the note in this shape. If a section is empty, write "None" (an empty section leaves the next Claude unable to tell whether it was forgotten or there really is nothing).

```markdown
# Handoff note

- Created: YYYY-MM-DD HH:MM
- Working folder: /path/to/project
- Branch / HEAD: main / abc1234 (first line of the commit message)
- Reason for pausing: context size / loading new skills / other

## Goal
What this whole piece of work is trying to achieve. The user's original request, as close to their own words as possible.

## Done
- Bullet points. Add commit hashes where there are commits

## Next steps
1. Make the first step concrete enough to start without hesitation (which file, what change, which command)
2. The steps after it
(If there is a plan document, say which task to resume from and point to the file)

## Pending decisions
- Things that need the user's confirmation, and the work held back until they decide

## Key context
- Decisions and the reasons for them (and who made them)
- What was tried and didn't work, and why
- Instructions and preferences the user gave in conversation that didn't go into memory
- Caveats and pitfalls

## State of the workspace
- Worktrees and work branches, and the state of each (committed / not merged, etc.)
- Jobs that were stopped (subagents, background jobs) and how far they got
- Test status (passing / failing tests and why)

## Files to read
- Files the next session should read first (plans, design docs, work logs, key source files)
```

A yardstick while writing: could the next Claude, reading only this note and the files it points to, start step 1 of "Next steps" without asking the user anything? If not, work out what is missing and add it.

### 6. Tell the user

Finish with a short summary:

- What you tidied up (commits, work log, memory, where the note is)
- A one-line summary of the next step, and the list of pending decisions if any
- How to start the new session:
  - To free up context only: `/clear`, then `/handoff:resume`
  - To load new skills, plugins or settings: quit Claude Code, start `claude` again in the same folder, then `/handoff:resume` (`/clear` does not reload some of these)

## When there is nothing to hand over

If the work is finished, don't hand it over — tidy up the way you would at the end of any task, and complete it. The goal is that the next session inherits nothing and can start from a clean slate.

1. **Confirm it is done**: run whatever the project uses to confirm completion, such as tests or a build, and check that it passes. If it doesn't, the work isn't finished; go back to step 0 and treat it as work to hand over
2. **Commit and integrate**: commit the changes and, following the git rules in the project's CLAUDE.md, merge and push as you normally would. Clean up worktrees and work branches that have served their purpose. Don't perform operations the rules say need the user's confirmation (publishing, releases, etc.) on your own; ask the user
3. **Work log**: if the project has a rule for it, write the entry and include it in the commit
4. **Memory**: save what will stay useful, by the same standard as step 4
5. **Clear out the old handoff note**: if a `.handoff/HANDOFF.md` is left over, move it to `.handoff/archive/`, so the next session doesn't resume work that is already done
6. **Tell the user**: say the work is complete and briefly list what you tidied up (commits, merge, push, work log, memory). Tell them the new session can start with just `/clear` or a restart of Claude Code, and that `/handoff:resume` is not needed
