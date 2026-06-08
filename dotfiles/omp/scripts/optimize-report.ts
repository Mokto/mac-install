#!/usr/bin/env bun
/**
 * OMP /optimize report — session mining + optimization candidates.
 * Usage: bun optimize-report.ts [--days 30] [--since <unix-ms>] [--json] [--emit-rules]
 */

import { existsSync } from "node:fs";
import { readdir, readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join, dirname, basename } from "node:path";
import { parseArgs } from "node:util";

const { values: args } = parseArgs({
  args: process.argv.slice(2).filter((a) => a !== "-"),
  options: {
    days: { type: "string", default: "30" },
    since: { type: "string" },
    json: { type: "boolean", default: false },
    "emit-rules": { type: "boolean", default: false },
    help: { type: "boolean", short: "h", default: false },
  },
});

if (args.help) {
  console.log("Usage: bun optimize-report.ts [--days 30] [--since <unix-ms>] [--json] [--emit-rules]");
  process.exit(0);
}

const DAYS = args.days ?? "30";
const BIN = dirname(import.meta.path);
const BUN = Bun.which("bun") ?? "bun";
const SESSIONS_DIR = join(homedir(), ".omp", "agent", "sessions");
const cutoffMs = args.since ? parseInt(args.since, 10) : Date.now() - parseInt(DAYS, 10) * 86_400_000;
const effectiveDays = args.since
  ? String(Math.max(1, Math.ceil((Date.now() - cutoffMs) / 86_400_000)))
  : DAYS;

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
  const byProject = new Map<string, Map<string, number>>();
  let parallelBatches = 0;
  let assistantTurns = 0;
  let subagentInvocations = 0;
  let subCompleted = 0;
  let subFailed = 0;
  let subCancelled = 0;
  let entries = 0;
  let compactionEvents = 0;
  let sessionsWithCompaction = 0;
  let rereadExtraCalls = 0;
  let rereadUniquePaths = 0;

  for (const file of files) {
    const project = basename(dirname(file)).replace(/^-/, "") || "unknown";
    if (!byProject.has(project)) byProject.set(project, new Map());
    const projectCounts = byProject.get(project)!;

    const seenPaths = new Map<string, number>();
    let fileCompactions = 0;

    for (const line of (await readFile(file, "utf8")).split("\n")) {
      if (!line.trim()) continue;
      let entry: SessionEntry;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }
      entries++;

      if (entry.type === "branch_summary") {
        fileCompactions++;
        compactionEvents++;
        continue;
      }

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
          projectCounts.set(name, (projectCounts.get(name) ?? 0) + 1);
          if (name === "read" && typeof tc.arguments?.path === "string") {
            const p = tc.arguments.path;
            seenPaths.set(p, (seenPaths.get(p) ?? 0) + 1);
          }
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

    if (fileCompactions > 0) sessionsWithCompaction++;
    for (const [, count] of seenPaths) {
      if (count > 1) {
        rereadExtraCalls += count - 1;
        rereadUniquePaths++;
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
    compaction: { sessions: sessionsWithCompaction, totalEvents: compactionEvents },
    rereads: { extraCalls: rereadExtraCalls, paths: rereadUniquePaths },
    byProject: Object.fromEntries(
      [...byProject.entries()].map(([p, m]) => [
        p,
        Object.fromEntries([...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8)),
      ]),
    ),
  };
}

const sessionFiles = await findSessionFiles();
const session = await analyzeSessions(sessionFiles);

const bashArgs = ["--days", effectiveDays];
if (args.json) bashArgs.push("--json");
if (args["emit-rules"]) bashArgs.push("--emit-rules");

const proc = Bun.spawn([BUN, join(BIN, "mine-bash-patterns.ts"), ...bashArgs], {
  stdout: "pipe",
  stderr: "pipe",
  stdin: "ignore",
});
const [bashOut, bashErr] = await Promise.all([
  new Response(proc.stdout).text(),
  new Response(proc.stderr).text(),
]);
await proc.exited;

const promptProc = Bun.spawn(
  [BUN, join(BIN, "mine-prompt-patterns.ts"), "--days", effectiveDays, ...(args.json ? ["--json"] : [])],
  { stdout: "pipe", stderr: "pipe", stdin: "ignore" },
);
const [promptOut] = await Promise.all([
  new Response(promptProc.stdout).text(),
  new Response(promptProc.stderr).text(),
]);
await promptProc.exited;

if (args.json) {
  console.log(
    JSON.stringify(
      {
        meta: { days: parseInt(effectiveDays, 10), since: cutoffMs, sessions: sessionFiles.length, entries: session.entries },
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
const sinceLabel = args.since ? new Date(cutoffMs).toLocaleString() : `last ${DAYS} days`;
console.log(`║  OMP /optimize report — ${sinceLabel}`);
console.log(`║  ${sessionFiles.length} sessions (${session.compaction.sessions} compacted, ${session.compaction.totalEvents} events), ${session.entries} entries`);
console.log(`╚══════════════════════════════════════════════════════════╝\n`);

console.log("── Tool usage (from sessions) ──");
for (const [tool, count] of Object.entries(session.toolCounts).slice(0, 14)) {
  const err = session.toolErrors[tool];
  console.log(`  ${tool.padEnd(14)} ${count}${err ? ` (${err} err)` : ""}`);
}
console.log(`  parallel batches: ${session.parallelBatches} / ${session.assistantTurns} turns`);
if (session.rereads.extraCalls > 0) {
  console.log(`  re-reads:         ${session.rereads.extraCalls} extra read calls across ${session.rereads.paths} unique paths`);
}

console.log("\n── Subagents ──");
console.log(`  task() calls: ${session.subagents.invocations}`);
if (session.subagents.invocations) {
  console.log(`  agents: ${JSON.stringify(session.subagents.byAgent)}`);
  console.log(`  batch sizes: ${JSON.stringify(session.subagents.batchSizes)}`);
  console.log(`  outcomes: ${JSON.stringify(session.subagents.outcomes)}`);
} else if (session.assistantTurns > 15) {
  console.log("  ⚠ no task() usage — consider explore/task for broad or parallel work");
}

console.log("\n── Per-project breakdown ──");
for (const [proj, counts] of Object.entries(session.byProject)) {
  const top = Object.entries(counts)
    .slice(0, 6)
    .map(([t, n]) => `${t}:${n}`)
    .join("  ");
  console.log(`  ${proj.padEnd(28)} ${top}`);
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
if (bash > 0 && bash >= (search + find) * 2 && bash >= 10) {
  console.log(`  [medium] tool-hygiene: ${bash} bash vs ${search} search + ${find} find — check bash patterns for redirectable commands`);
}
const lsp = (session.toolCounts.lsp ?? 0) as number;
const codeIntel = (session.toolCounts.read ?? 0) + search + (session.toolCounts.edit ?? 0) as number;
if (codeIntel > 20 && lsp < codeIntel * 0.05) {
  console.log(`  [high] tool-hygiene: lsp used ${lsp}x vs ${codeIntel} read+search+edit — definition/references/rename should go through lsp`);
}
if (session.compaction.sessions > 0) {
  const pct = Math.round((session.compaction.sessions / sessionFiles.length) * 100);
  console.log(`  [${pct >= 30 ? "high" : "medium"}] session-patterns: ${session.compaction.sessions}/${sessionFiles.length} sessions (${pct}%) hit compaction — consider shorter sessions or todo-tracking`);
}
if (session.rereads.extraCalls >= 5) {
  console.log(`  [medium] tool-hygiene: ${session.rereads.extraCalls} redundant re-reads across ${session.rereads.paths} paths — read once, store in context`);
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
