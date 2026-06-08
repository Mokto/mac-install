#!/usr/bin/env bun
/**
 * mine-prompt-patterns.ts
 *
 * Read the OMP HistoryStorage SQLite DB, cluster prompts by semantic shape,
 * and emit frequency-ranked summaries of what you ask the agent most.
 *
 * This is pure read — no writes to the DB.
 *
 * Usage:
 *   bun bin/mine-prompt-patterns.ts [--days N] [--min-count N] [--json] [--raw N]
 *
 * Defaults: --days 30  --min-count 2
 *
 * DB schema:
 *   history(id INTEGER PK, prompt TEXT, created_at INTEGER, cwd TEXT, session_id TEXT)
 *   history_fts  (FTS5 virtual table on prompt)
 */

import { existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { parseArgs } from "node:util";
import { Database } from "bun:sqlite";

const { values: args } = parseArgs({
  args: process.argv.slice(2),
  options: {
    days: { type: "string", default: "30" },
    "min-count": { type: "string", default: "2" },
    json: { type: "boolean", default: false },
    raw: { type: "string" },
    help: { type: "boolean", default: false },
  },
  allowPositionals: false,
});

if (args.help) {
  console.log(`Usage: bun bin/mine-prompt-patterns.ts [options]

Options:
  --days N        Look back N days of history (default: 30)
  --min-count N   Only show patterns seen >= N times (default: 2)
  --json          Output raw cluster data as JSON
  --raw N         Print last N raw prompts instead of clustering
`);
  process.exit(0);
}

const LOOK_BACK_DAYS = parseInt(args.days ?? "30", 10);
const MIN_COUNT = parseInt(args["min-count"] ?? "2", 10);
const OUTPUT_JSON = args.json === true;
const RAW_N = args.raw !== undefined ? parseInt(args.raw, 10) : null;

const DB_PATH = join(homedir(), ".omp", "agent", "history.db");

if (!existsSync(DB_PATH)) {
  console.error(`History DB not found: ${DB_PATH}`);
  process.exit(1);
}

const db = new Database(DB_PATH, { readonly: true });

// ---------------------------------------------------------------------------
// Raw mode — just show recent prompts
// ---------------------------------------------------------------------------

if (RAW_N !== null) {
  const cutoff = Math.floor((Date.now() - LOOK_BACK_DAYS * 86_400_000) / 1000);
  const rows = db
    .prepare(
      `SELECT prompt, created_at, cwd
       FROM history
       WHERE created_at >= ?
       ORDER BY created_at DESC
       LIMIT ?`
    )
    .all(cutoff, RAW_N) as Array<{ prompt: string; created_at: number; cwd: string }>;

  for (const row of rows) {
    const ts = new Date(row.created_at * 1000).toISOString().slice(0, 16);
    const preview = row.prompt.replace(/\s+/g, " ").trim().slice(0, 120);
    const proj = row.cwd.replace(homedir(), "~");
    console.log(`[${ts}] (${proj}) ${preview}`);
  }
  console.log(`\n${rows.length} prompt(s)`);
  db.close();
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Prompt normalization → intent shape
// ---------------------------------------------------------------------------

/**
 * Reduce a raw prompt to a short canonical intent key.
 *
 * Strategy:
 *   1. Lowercase, collapse whitespace
 *   2. Strip URLs, file paths, quoted strings, hex hashes, numbers
 *   3. Extract the imperative verb + first object noun from the first sentence
 *   4. Truncate to ~60 chars
 *
 * This is purely lexical — no embeddings. Fast and reproducible.
 */
function toShape(prompt: string): string {
  let s = prompt.toLowerCase().replace(/\s+/g, " ").trim();

  // Drop everything after the first sentence break (question mark, period, newline)
  s = s.split(/[.!?\n]/)[0]?.trim() ?? s;

  // Strip URLs
  s = s.replace(/https?:\/\/\S+/g, "");
  // Strip file paths (absolute or home-relative)
  s = s.replace(/(?:~|\/[\w./~-]+)/g, "");
  // Strip quoted strings
  s = s.replace(/"[^"]*"/g, "").replace(/'[^']*'/g, "");
  // Strip hex hashes (git SHAs etc.)
  s = s.replace(/\b[0-9a-f]{7,}\b/g, "");
  // Strip bare numbers
  s = s.replace(/\b\d+\b/g, "");
  // Strip markdown bold/italic markers
  s = s.replace(/[*_`#]/g, "");
  // Collapse whitespace again
  s = s.replace(/\s+/g, " ").trim();

  // Pull the imperative verb + next 4 tokens (rough intent fingerprint)
  const tokens = s.split(" ").filter(Boolean);
  const STOP_WORDS = new Set([
    "a", "an", "the", "in", "on", "at", "to", "for", "of", "and",
    "or", "but", "with", "from", "by", "as", "this", "that", "it",
    "is", "are", "was", "were", "be", "been", "being", "have", "has",
    "had", "do", "does", "did", "will", "would", "could", "should",
    "may", "might", "can", "i", "you", "we", "they", "my", "your",
  ]);

  const meaningful = tokens.filter((t) => !STOP_WORDS.has(t)).slice(0, 5);
  return meaningful.join(" ").slice(0, 60) || s.slice(0, 60);
}

// ---------------------------------------------------------------------------
// Rough clustering: group shapes by longest-common-prefix (first 3 tokens)
// ---------------------------------------------------------------------------

function clusterKey(shape: string): string {
  return shape.split(" ").slice(0, 3).join(" ");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const cutoff = Math.floor((Date.now() - LOOK_BACK_DAYS * 86_400_000) / 1000);

const rows = db
  .prepare(
    `SELECT prompt, created_at, cwd
     FROM history
     WHERE created_at >= ?
     ORDER BY created_at DESC`
  )
  .all(cutoff) as Array<{ prompt: string; created_at: number; cwd: string }>;

db.close();

if (!rows.length) {
  console.log(`No prompts in the last ${LOOK_BACK_DAYS} days.`);
  process.exit(0);
}

// shape → { count, examples, projects }
const clusters = new Map<
  string,
  { count: number; examples: string[]; projects: Set<string> }
>();

for (const row of rows) {
  const shape = toShape(row.prompt);
  const key = clusterKey(shape);
  const proj = row.cwd.replace(homedir(), "~").replace(/^~\/Projects\//, "");

  const entry = clusters.get(key) ?? { count: 0, examples: [], projects: new Set() };
  entry.count++;
  entry.projects.add(proj);
  if (entry.examples.length < 2) {
    const preview = row.prompt.replace(/\s+/g, " ").trim().slice(0, 100);
    if (!entry.examples.includes(preview)) entry.examples.push(preview);
  }
  clusters.set(key, entry);
}

const ranked = [...clusters.entries()]
  .filter(([, v]) => v.count >= MIN_COUNT)
  .sort((a, b) => b[1].count - a[1].count);

if (OUTPUT_JSON) {
  console.log(
    JSON.stringify(
      ranked.map(([key, { count, examples, projects }]) => ({
        pattern: key,
        count,
        projects: [...projects],
        examples,
      })),
      null,
      2
    )
  );
  process.exit(0);
}

console.log(`\nPrompt pattern report — last ${LOOK_BACK_DAYS} days, ${rows.length} prompts\n`);
console.log(`${"pattern".padEnd(45)} count  projects`);
console.log("─".repeat(72));

for (const [key, { count, examples, projects }] of ranked) {
  const projList = [...projects].slice(0, 3).join(", ");
  console.log(`${key.padEnd(45)} ${String(count).padStart(5)}  ${projList}`);
  for (const ex of examples) {
    console.log(`  → ${ex.slice(0, 90)}`);
  }
}

console.log(`\n${rows.length} total prompts, ${clusters.size} unique patterns`);
