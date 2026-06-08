#!/usr/bin/env bun
/**
 * OMP /optimize report — session mining + optimization candidates.
 * Usage: bun optimize-report.ts [--days 30] [--json] [--emit-rules]
 */

import { existsSync } from "node:fs";
import { readdir, readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { parseArgs } from "node:util";

const { values: args } = parseArgs({
  options: {
    days: { type: "string", default: "30" },
    json: { type: "boolean", default: false },
    "emit-rules": { type: "boolean", default: false },
    help: { type: "boolean", short: "h", default: false },
  },
});

if (args.help) {
  console.log("Usage: bun optimize-report.ts [--days 30] [--json] [--emit-rules]");
  process.exit(0);
}

const DAYS = args.days ?? "30";
const BIN = dirname(import.meta.path);
const SESSIONS_DIR = join(homedir(), ".omp", "agent", "sessions");
const cutoffMs = Date.now() - parseInt(DAYS, 10) * 86_400_000;

interface SessionEntry {
  type: string;
  message?: {
    role?: string;
    content?: Array<{ type?: string; name?: string; arguments?: Record<string, unknown>; text?: string }>;
    toolName?: string;
    isError?: boolean;
  };
}

async function findSessionFiles(): Promise<string[]> {
  const files: string[] = [];
  let buckets: string[];
  try {
    buckets = await readdir(SESSIONS_DIR);
  } catch {
    return files;
  }
  for (const bucket of buckets) {
    const bucketPath = join(SESSIONS_DIR, bucket);
    try {
      if (!(await stat(bucketPath)).isDirectory()) continue;
      for (const entry of await readdir(bucketPath)) {
        if (!entry.endsWith(".jsonl")) continue;
        const full = join(bucketPath, entry);
        if ((await stat(full)).mtimeMs >= cutoffMs) files.push(full);
      }
    } catch {
      /* skip */
    }
  }
  return files;
}

function promptShape(prompt: string): string {
  let s = prompt.trim();
  if (s.startsWith("/")) return s.split(/\s+/)[0] ?? s;
  s = s.toLowerCase().replace(/[`'"]/g, "");
  s = s.replace(/\b(?:the|a|an|please|can you|could you|help me|show me)\b/g, " ");
  s = s.replace(/https?:\/\/\S+/g, " URL ");
  s = s.replace(/\/[\w./-]+/g, " PATH ");
  s = s.replace(/\s+/g, " ").trim();
  return s.split(" ").filter(Boolean).slice(0, 4).join(" ");
}

async function analyzeSessions(files: string[]) {
  const toolCounts = new Map<string, number>();
  const toolErrors = new Map<string, number>();
  const subagentByType = new Map<string, number>();
  const batchSizes = new Map<number, number>();
  const userShapes = new Map<string, number>();
  let parallelBatches = 0;
  let assistantTurns = 0;
  let subagentInvocations = 0;
  let subCompleted = 0;
  let subFailed = 0;
  let subCancelled = 0;
  let entries = 0;

  for (const file of files) {
    for (const line of (await readFile(file, "utf8")).split("\n")) {
      if (!line.trim()) continue;
      let entry: SessionEntry;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }
      entries++;
      if (entry.type !== "message" || !entry.message) continue;
      const { role, content } = entry.message;

      if (role === "user" && content) {
        for (const b of content) {
          if (b.type === "text" && b.text) {
            const shape = promptShape(b.text);
            if (shape.length > 1) userShapes.set(shape, (userShapes.get(shape) ?? 0) + 1);
          }
        }
      }

      if (role === "assistant" && content) {
        const tcs = content.filter((b) => b.type === "toolCall");
        if (tcs.length) assistantTurns++;
        if (tcs.length > 1) parallelBatches++;
        for (const tc of tcs) {
          const name = tc.name ?? "?";
          toolCounts.set(name, (toolCounts.get(name) ?? 0) + 1);
          if (name === "task") {
            subagentInvocations++;
            const agent = String(tc.arguments?.agent ?? "task");
            subagentByType.set(agent, (subagentByType.get(agent) ?? 0) + 1);
            const tasks = tc.arguments?.tasks;
            const n = Array.isArray(tasks) ? tasks.length : 1;
            batchSizes.set(n, (batchSizes.get(n) ?? 0) + 1);
          }
        }
      }

      if (role === "toolResult") {
        if (entry.message.isError) {
          const tn = entry.message.toolName ?? "?";
          toolErrors.set(tn, (toolErrors.get(tn) ?? 0) + 1);
        }
        if (entry.message.toolName === "task") {
          const blob = JSON.stringify(entry.message.content ?? "");
          if (/cancelled/i.test(blob)) subCancelled++;
          else if (/failed|error/i.test(blob)) subFailed++;
          else if (/succeeded|completed/i.test(blob)) subCompleted++;
        }
      }
    }
  }

  return {
    entries,
    toolCounts: Object.fromEntries([...toolCounts.entries()].sort((a, b) => b[1] - a[1])),
    toolErrors: Object.fromEntries(toolErrors),
    parallelBatches,
    assistantTurns,
    subagents: {
      invocations: subagentInvocations,
      byAgent: Object.fromEntries(subagentByType),
      batchSizes: Object.fromEntries(batchSizes),
      outcomes: { completed: subCompleted, failed: subFailed, cancelled: subCancelled },
    },
    userShapes: [...userShapes.entries()]
      .filter(([, c]) => c >= 2)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 12)
      .map(([shape, count]) => ({ shape, count })),
  };
}

const sessionFiles = await findSessionFiles();
const session = await analyzeSessions(sessionFiles);

const bashArgs = ["--days", DAYS];
if (args.json) bashArgs.push("--json");
if (args["emit-rules"]) bashArgs.push("--emit-rules");

const proc = Bun.spawn(["bun", join(BIN, "mine-bash-patterns.ts"), ...bashArgs], {
  stdout: "pipe",
  stderr: "pipe",
});
const bashOut = await new Response(proc.stdout).text();
const bashErr = await new Response(proc.stderr).text();
await proc.exited;

const promptProc = Bun.spawn(["bun", join(BIN, "mine-prompt-patterns.ts"), "--days", DAYS, ...(args.json ? ["--json"] : [])], {
  stdout: "pipe",
  stderr: "pipe",
});
const promptOut = await new Response(promptProc.stdout).text();
await promptProc.exited;

if (args.json) {
  console.log(
    JSON.stringify(
      {
        meta: { days: parseInt(DAYS, 10), sessions: sessionFiles.length, entries: session.entries },
        session,
        bash: bashOut,
        prompts: promptOut,
      },
      null,
      2,
    ),
  );
  process.exit(0);
}

console.log(`\n╔══════════════════════════════════════════════════════════╗`);
console.log(`║  OMP /optimize report — last ${DAYS} days`);
console.log(`║  ${sessionFiles.length} sessions, ${session.entries} entries`);
console.log(`╚══════════════════════════════════════════════════════════╝\n`);

console.log("── Tool usage (from sessions) ──");
for (const [tool, count] of Object.entries(session.toolCounts).slice(0, 14)) {
  const err = session.toolErrors[tool];
  console.log(`  ${tool.padEnd(14)} ${count}${err ? ` (${err} err)` : ""}`);
}
console.log(`  parallel batches: ${session.parallelBatches} / ${session.assistantTurns} turns`);

console.log("\n── Subagents ──");
console.log(`  task() calls: ${session.subagents.invocations}`);
if (session.subagents.invocations) {
  console.log(`  agents: ${JSON.stringify(session.subagents.byAgent)}`);
  console.log(`  batch sizes: ${JSON.stringify(session.subagents.batchSizes)}`);
  console.log(`  outcomes: ${JSON.stringify(session.subagents.outcomes)}`);
} else if (session.assistantTurns > 15) {
  console.log("  ⚠ no task() usage — consider explore/task for broad or parallel work");
}

if (session.userShapes.length) {
  console.log("\n── Repeated user prompts (sessions) ──");
  for (const { shape, count } of session.userShapes) {
    console.log(`  ${shape.padEnd(32)} ${count}x  → skill/slash-command candidate`);
  }
}

console.log("\n── Bash command shapes ──");
console.log(bashOut.trim());
if (bashErr.trim()) console.error(bashErr.trim());

console.log("\n── Prompt history (history.db) ──");
console.log(promptOut.trim());

console.log("\n── Quick recommendations ──");
const bash = (session.toolCounts.bash ?? 0) as number;
const search = (session.toolCounts.search ?? 0) as number;
const find = (session.toolCounts.find ?? 0) as number;
if (bash > search + find) {
  console.log(`  [medium] tool-hygiene: ${bash} bash vs ${search} search + ${find} find — enable bashInterceptor`);
}
if (session.parallelBatches < session.assistantTurns * 0.12 && session.assistantTurns > 10) {
  console.log(`  [medium] parallelism: batch independent tool calls in single turns`);
}
for (const { shape, count } of session.userShapes.slice(0, 3)) {
  if (!shape.startsWith("/")) {
    console.log(`  [${count >= 3 ? "high" : "medium"}] prompt-shortcut: "${shape}" (${count}x)`);
  }
}
console.log();
