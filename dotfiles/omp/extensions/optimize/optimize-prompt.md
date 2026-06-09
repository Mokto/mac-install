# Optimize

Mine OMP session history and return **actionable optimization candidates**. Advisory only — do not apply changes unless the user asks.

## Your job

1. Read all sections of the analyzer output below.
2. Return a structured candidate list grouped by category.

Start with what the sessions actually show — tool mix, parallelism rate, subagent patterns, error-prone tools. Bash command data is supplementary; don't lead with it.

### session-patterns
The primary analysis. From the session data:
- **Tool distribution**: which tools dominate? Are `bash`/`eval` used where `read`/`search`/`find`/`edit` should be?
- **Parallelism rate**: `parallel batches / assistant turns`. Below ~15% on a busy session → missed opportunities. Cite specific tools that appear in long sequential chains.
- **Compaction**: sessions in the header marked as compacted hit the context window limit. A high fraction (>20%) → sessions are too long, unfocused, or should use `todo`-tracking to reduce state held in context. A low fraction is fine.
- **Re-reads**: `re-reads: N extra read calls across M paths` in the tool usage section. Each is a wasted round-trip — the file was already in context. Flag if N ≥ 5.
- **Error-prone tools**: tools with high error counts relative to call count (shown inline as `(N err)`) — worth noting if a pattern is clear.
- **Subagent batch sizes**: batch size 1 on every `task()` call = missed parallel fan-out.

### per-project
The `── Per-project breakdown ──` section shows tool distribution per project (working directory). Look for:
- Projects where `bash` dominates over `read`/`search` — bash-heavy projects may have different conventions or may benefit from interceptor rules.
- Projects with very low `lsp` usage despite heavy `read`+`search`+`edit` — LSP is always better for definition/references/rename in code repos.
- Projects where parallelism is clearly missing (can be inferred from the global rate plus which projects have the most sessions).

Only flag per-project candidates that differ meaningfully from the global pattern — don't repeat what's already in `session-patterns`.

### lsp-underuse
Check the quick recommendations section. If `lsp` call count is less than ~5% of `read + search + edit` combined, this is the highest-priority hygiene issue. LSP-native operations (`definition`, `references`, `rename`, `code_actions`, `hover`) are strictly more accurate than text search for code intelligence. Cite the ratio and suggest specific operations that should be switched.

### prompt-shortcut
Repeated user intents → propose a skill, slash command, or extension. Look at the prompt-shape clusters. Only flag if a shape appears ≥3 times and isn't already a slash command.

### subagent-playbook
When `task()` was used well (agent type, batch width, outcome) vs missed opportunities:
- Broad repo exploration → `explore` agent
- Parallel disjoint file work → `task` with wide batch
- Mechanical find-replace → `quick_task`
- Architecture decisions → `plan` or `oracle`

Only flag a miss if there's actual evidence from the session (e.g. many sequential single-file reads with no task() call).

### tool-hygiene
Anti-patterns from the data: sequential reads that could be batched, high bash-to-search ratio, redundant re-reads of the same file.

**Bash interceptor rules**: only raise this if a specific shell command pattern appears ≥5 times across sessions AND the redirect to a native tool is clearly better (not just possible). Include a suggested regex pattern if the signal is strong. Skip this entire sub-point if bash usage is low or patterns are varied. Note: `cat`, `head`, `tail`, `grep`, `rg`, `find`, `fd` are already intercepted by OMP's built-in stream rules — do not flag these as candidates regardless of their frequency in the report.

### config-tweaks
Only if signal is strong and specific. E.g. a skill that's disabled but clearly would help, a model role that's missing. Do NOT suggest enabling `bashInterceptor` globally unless the bash-pattern analysis found multiple high-frequency, redirectable patterns.

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
- Ground every candidate in specific numbers from the report. No speculation.
