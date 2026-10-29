# handoff

Claude Code skills for switching to a fresh session without losing your place.

When the context window fills up, or you need to restart to load new skills or plugins, `/handoff:save` stops at a clean point and moves everything that lives only in the conversation into files the next session can read. In the new session, `/handoff:resume` reads it back, checks it against the repository, and asks you before carrying on.

## Skills

### `/handoff:save`

1. Decides whether any work is left to hand over.
2. If there is, it:
   - waits for running subagents and leaves decisions that are yours to make for you;
   - commits uncommitted changes in the main tree and every worktree (unfinished work as a WIP commit, never merged);
   - writes the work log, if the project's CLAUDE.md asks for one;
   - saves lasting lessons and preferences to auto-memory (progress stays out of memory);
   - writes `.handoff/HANDOFF.md`: goal, what's done, concrete next steps, pending decisions, reasons and dead ends, workspace state, and files to read. `.handoff/` is kept out of git through `.git/info/exclude`, so `.gitignore` is untouched.
3. If nothing is left, it wraps the task up instead: runs the tests, commits, merges and pushes as the project's rules allow, cleans up worktrees, archives any stale handoff note, and tells you no resume is needed.

### `/handoff:resume`

1. Reads `.handoff/HANDOFF.md`.
2. Compares the branch, HEAD, uncommitted changes and worktrees with the note, and reports anything that moved since (for example, a teammate's commit).
3. Summarizes the goal, the next step and pending decisions, and waits for your go-ahead before changing anything.
4. Moves the used note to `.handoff/archive/`.

Both skills also trigger from plain requests such as "the context is getting full, let's switch sessions" or "continue from last time", in English or Japanese. Notes and messages are written in the language you are using.

## Usage

```
/handoff:save
/clear                 # or quit and restart `claude` to load new skills, plugins or settings
/handoff:resume
```

## Install

At the prompt of a Claude Code terminal session:

```
/plugin install handoff --marketplace arcfjmt/handoff
```

Answer `y` to add the marketplace, then pick a scope (user scope makes the skills available in every session).

## Develop

```
claude plugin validate .
claude --plugin-dir .
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

The test cases live in each skill's `evals/` folder. Each case builds a scratch repository with its `place-files.sh`.

## License

MIT
