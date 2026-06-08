# Oh My Pi (omp)

[oh-my-pi](https://github.com/can1357/oh-my-pi) is a terminal coding agent with the IDE wired in.
Fork of [Pi](https://github.com/badlogic/pi-mono) by @mariozechner.

- **Harness:** hash-anchored edits (`edit`), in-process ripgrep/glob/find, persistent Python + Bun eval kernels that can call back into agent tools
- **Code intelligence:** 13 LSP ops (rename, references, definition, diagnostics…) wired into every write
- **Debugger:** 27 DAP ops — lldb, dlv, debugpy
- **Subagents:** `task` fans out into isolated worktrees with schema-validated typed results
- **Memory:** `retain`/`recall` + per-session compression (Hindsight)
- **Stream rules:** regex match aborts mid-token, injects rule, retries — no context tax
- **ACP:** runs inside Zed; same agent surface as the CLI TUI
- **GitHub:** PRs/issues are paths; `read pr://N` works like `read` on local files
- **Web:** `web_search` + `read <url>` over 14 providers; arxiv PDFs, GH pages, SO threads → structured markdown
- **Models:** 40+ providers; prompts tuned per-model; 32 built-in tools
- **Config:** reads Cursor MDC, Cline `.clinerules`, Codex `AGENTS.md`, Copilot `applyTo` natively

Website: <https://omp.sh>
---

# OMP Extension Development — ACP Mode Learnings

Lessons learned debugging `/optimize` hanging in Zed ACP (agent client protocol) mode
while working correctly in the CLI TUI.

---

## `pi.sendUserMessage` is fire-and-forget in ACP mode

**Problem:** calling `pi.sendUserMessage(message)` from an extension command handler
starts a new agent turn but returns immediately. The ACP `promptTurn` subscription
that delivers streaming events to Zed only stays active while the handler has not
yet returned. By the time the LLM responds, the subscription has been torn down
and the response is produced in memory but never delivered to Zed.

**Fix:** keep the handler alive until the agent turn completes:

```ts
pi.sendUserMessage(message);
// One event-loop tick lets session.prompt() start before we poll for idle.
await new Promise(r => setTimeout(r, 0));
// Block until agent_end fires and #finishPrompt delivers the response to Zed.
await ctx.waitForIdle();
```

The `setTimeout(0)` is necessary because `sendUserMessage` is fire-and-forget at
the ACP layer (`record.session.sendUserMessage(...).catch(log)`). Without yielding,
`waitForIdle()` may find the session still idle and return immediately before the
agent turn has started.

**Why TUI works without this:** in the CLI TUI, `sendUserMessage` goes through a
different path that directly calls `session.prompt()` in a tracked context.

---

## `deliverAs: "followUp"` does not work in ACP mode when idle

`pi.sendUserMessage(message, { deliverAs: "followUp" })` queues the message to run
after the *current* turn ends. In ACP mode the session is idle when the extension
command fires, so there is no current turn to follow up — the message is queued
forever and never delivered.

---

## `pi.sendMessage` with `triggerTurn: true` is blocked in ACP mode

`sendMessage` with `{ deliverAs: "followUp", triggerTurn: true }` is guarded by
`clientBridge.deferAgentInitiatedTurns` in ACP mode, which queues it into
`#queueHiddenNextTurnMessage` — never fired.

In TUI mode `#clientBridge` is `undefined`, so the guard does not apply and
`agent.prompt()` runs directly. This is why it worked in CLI but not Zed.

---

## ACP extension notifications are not visible in Zed's UI — use `sendUserMessage`

`ctx.ui.notify(...)` in ACP mode sends a notification over ACP
(`logger.debug("ACP extension notification", ...)`). Zed logs it but does not
display it in the agent panel.

**Any handler that needs to show feedback in Zed must use `sendUserMessage` + `waitForIdle`
on every exit path (success, error, early return):**

```ts
const msg = 'Checkpoint saved.';
ctx.ui.notify(msg, 'info');  // still useful in CLI TUI
pi.sendUserMessage(msg);
await new Promise(r => setTimeout(r, 0));
await ctx.waitForIdle();
```

A handler that only calls `ctx.ui.notify` and returns produces no visible output in
Zed — the turn completes silently. This includes error paths with early `return`.
Diagnostics relying on `notify` alone are invisible to the user in ACP mode.
---

## How to debug ACP extension issues

```sh
# Tail the OMP log while reproducing in Zed
tail -f ~/.omp/logs/omp.$(date +%Y-%m-%d).log | grep -E "optimize|error|notification|auto-thinking"
```

Key signals:
- `ACP extension notification <message>` — `ctx.ui.notify` fired (handler ran)
- `auto-thinking: classification failed` — a new agent LLM turn started
- `ACP extension sendUserMessage failed` / `sendMessage failed` — the fire-and-forget caught an error

If the notification fires but no auto-thinking follows, `sendUserMessage` was never
called (script failed, empty output, etc.).

If notification → auto-thinking fires but nothing appears in Zed, the agent turn ran
but the ACP subscription was already torn down — missing `waitForIdle()`.

---

## OMP extension directory scanning picks up all `.ts` files

OMP scans each registered extension directory and attempts to load every `.ts` file
it finds as an extension factory. Place helper scripts (e.g. `mine-*.ts`,
`optimize-report.ts`) in `~/.omp/scripts/`, not inside the extension directory, or
they will be loaded as extensions and emit "does not export a valid factory function"
errors on every session start.
