# Optimize

Mine your OMP usage history and return **actionable optimization candidates**. Advisory only — do not apply changes unless the user asks.

## Run the analyzer

```bash
bun ~/Projects/mac-install/dotfiles/omp/extensions/optimize/optimize-report.ts
```

Optional flags:
- `--days 60` — look back further (default 30)
- `--json` — machine-readable output
- `--emit-rules` — append `bashInterceptor` YAML snippets

## Your job

1. **Run** the report script (use `bash` tool).
2. **Read** all sections: recommendations, bash shapes, tool usage, subagents, prompt patterns.
3. **Return** a structured candidate list grouped by category:

### bashInterceptor
Frequent shell commands that should redirect to native OMP tools (`read`, `search`, `find`, `edit`, `write`). Include suggested regex rule if `--emit-rules` wasn't passed but candidate is strong (≥5 occurrences).

### prompt-shortcut
Repeated user intents → propose a skill, slash command, or extension. Slash commands like `/sonnet` are already shortcuts — suggest new ones for repeated natural-language shapes.

### subagent-playbook
When `task()` was used well (agent type, batch width, outcome) vs **missed opportunities**:
- Broad repo exploration → `explore` agent
- Parallel disjoint file work → `task` with wide batch
- Mechanical find-replace → `quick_task`
- Architecture decisions → `plan` or `oracle`

### tool-hygiene
Anti-patterns from the data: bash-for-grep, sequential reads, high error tools, low parallelism.

### config-tweaks
Only if signal is strong — e.g. enable `bashInterceptor`, adjust `skills.enabled`, add `modelRoles`.

## Output format

For each candidate:

| Field | Content |
|-------|---------|
| **category** | one of above |
| **priority** | high / medium / low |
| **signal** | frequency + example from report |
| **action** | concrete next step |
| **effort** | low / med / high |

End with **top 3** picks if the list is long.

## Constraints

- Do NOT edit config files, install launchagents, or create skills unless user confirms.
- If sessions are sparse (<5 files), say so and suggest running again after more usage.
- Cross-check slash-command prompts (`/mcp`, `/model`, etc.) — those are already optimized.
