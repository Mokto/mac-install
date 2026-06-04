# Claude Instructions

## SSH
SSH keys are managed exclusively via the 1Password agent. Never run `ssh-add` with key paths. If git push fails with auth errors, the fix is unlocking 1Password.

## Secrets / 1Password CLI
- Fetch any given secret at most once per session. After a successful `op read`/`op item get`, reuse the value already in context for the rest of the session — do not re-run `op` for a secret you've already retrieved. Re-fetching only triggers extra unlock prompts; it adds no security, since the value is already in context after the first read.
- Never write a secret to a file (including this one), commit it, or echo it into output that persists.

## Git
- Always create a new branch per task, commit, push, and open a PR
- Never push directly to main unless if asked directly

## Style
- Terse responses — no trailing summaries, no narration of what was just done
- No emojis unless asked
- No comments in code unless the WHY is non-obvious

## Project-specific context

When working on the **biomejs/biome** project, read `claude/biome/CONTEXT.md` first before writing any code, changesets, or PR descriptions. It contains patterns and expectations distilled from human reviewer feedback on past contributions.
