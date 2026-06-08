#!/usr/bin/env bun
/**
 * mine-bash-patterns.ts
 *
 * Daily job: scan OMP session JSONL files → extract bash tool calls →
 * normalize to command shapes → rank by frequency → emit candidate
 * interceptor rules for patterns not yet covered by OMP defaults.
 *
 * Usage:
 *   bun bin/mine-bash-patterns.ts [--days N] [--min-count N] [--json] [--emit-rules]
 *
 * Defaults: --days 30  --min-count 3
 */

import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";
import { parseArgs } from "node:util";

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const { values: args } = parseArgs({
  args: process.argv.slice(2),
  options: {
    days: { type: "string", default: "30" },
    "min-count": { type: "string", default: "3" },
    json: { type: "boolean", default: false },
    "emit-rules": { type: "boolean", default: false },
    help: { type: "boolean", default: false },
  },
  allowPositionals: false,
});

if (args.help) {
  console.log(`Usage: bun bin/mine-bash-patterns.ts [options]

Options:
  --days N        Look back N days of session files (default: 30)
  --min-count N   Only report shapes seen >= N times (default: 3)
  --json          Output raw frequency table as JSON
  --emit-rules    Print candidate bashInterceptor rule YAML snippets
`);
  process.exit(0);
}

const LOOK_BACK_DAYS = parseInt(args.days ?? "30", 10);
const MIN_COUNT = parseInt(args["min-count"] ?? "3", 10);
const OUTPUT_JSON = args.json === true;
const EMIT_RULES = args["emit-rules"] === true;

// ---------------------------------------------------------------------------
// Default interceptor patterns already covered by OMP
// (from DEFAULT_BASH_INTERCEPTOR_RULES in settings-schema.ts)
// We won't suggest additional rules for these.
// ---------------------------------------------------------------------------

const ALREADY_COVERED: RegExp[] = [
  /^\s*(cat|head|tail|less|more)\b/,
  /^\s*(grep|rg|ripgrep|ag|ack)\b/,
  /^\s*(find|fd|locate)\b/,
  /^\s*sed\s+-i/,
  /^\s*perl\s+-i/,
  /^\s*awk\s+(-i\s+inplace|-i\b)/,
  /^\s*(echo|printf)\s.*>/, // redirection writes
  /^\s*cat\s+<</, // heredoc writes
];

// Binaries where native tool interception makes clear sense
const NATIVE_TOOL_MAP: Record<string, { tool: string; reason: string }> = {
  ls: { tool: "find", reason: "use find tool for directory listings" },
  grep: { tool: "search", reason: "use search tool for regex content search" },
  rg: { tool: "search", reason: "use search tool for regex content search" },
  find: { tool: "find", reason: "use find tool for file discovery" },
  cat: { tool: "read", reason: "use read tool to view file contents" },
  head: { tool: "read", reason: "use read tool with offset/limit selectors" },
  tail: { tool: "read", reason: "use read tool with offset/limit selectors" },
  "sed -i": { tool: "edit", reason: "use edit tool for in-place file edits" },
  "awk -i": { tool: "edit", reason: "use edit tool for in-place file edits" },
};

// ---------------------------------------------------------------------------
// Session discovery
// ---------------------------------------------------------------------------

const SESSIONS_DIR = join(homedir(), ".omp", "agent", "sessions");

async function findSessionFiles(cutoffMs: number): Promise<string[]> {
  const results: string[] = [];
  let projectDirs: string[];

  try {
    projectDirs = await readdir(SESSIONS_DIR);
  } catch {
    return results;
  }

  for (const dir of projectDirs) {
    const dirPath = join(SESSIONS_DIR, dir);
    let files: string[];
    try {
      files = await readdir(dirPath);
    } catch {
      continue;
    }

    for (const file of files) {
      if (!file.endsWith(".jsonl")) continue;
      const fullPath = join(dirPath, file);
      try {
        const s = await stat(fullPath);
        if (s.mtimeMs >= cutoffMs) results.push(fullPath);
      } catch {
        // skip unreadable
      }
    }
  }

  return results;
}

// ---------------------------------------------------------------------------
// JSONL parsing
// ---------------------------------------------------------------------------

function* extractBashCommands(jsonlText: string): Generator<string> {
  for (const rawLine of jsonlText.split("\n")) {
    const line = rawLine.trim();
    if (!line) continue;

    let obj: Record<string, unknown>;
    try {
      obj = JSON.parse(line) as Record<string, unknown>;
    } catch {
      continue;
    }

    if (obj.type !== "message") continue;
    const msg = obj.message as Record<string, unknown> | undefined;
    if (!msg || msg.role !== "assistant") continue;
    const content = msg.content;
    if (!Array.isArray(content)) continue;

    for (const block of content) {
      if (
        typeof block !== "object" ||
        block === null ||
        (block as Record<string, unknown>).type !== "toolCall" ||
        (block as Record<string, unknown>).name !== "bash"
      )
        continue;

      const tc = block as Record<string, unknown>;
      const arguments_ = tc.arguments as Record<string, unknown> | undefined;
      const cmd = arguments_?.command;
      if (typeof cmd === "string" && cmd.trim()) yield cmd.trim();
    }
  }
}

// ---------------------------------------------------------------------------
// Command normalization
// ---------------------------------------------------------------------------

// A valid shell binary: starts with letter/digit, may contain alphanumerics,
// dashes, dots, underscores. No path separators (we strip those separately).
const BINARY_RE = /^[a-zA-Z][a-zA-Z0-9_.-]*$/;

// A valid bare subcommand word (no flags, paths, or specials)
const SUBCMD_RE = /^[a-z][a-z0-9_-]{0,30}$/;

/**
 * Split a command chain (&&, ;, ||) into individual segments.
 * Strips leading `cd <path>` segments since OMP canonicalizes those.
 * Ignores pipeline (|) — keeps first stage only.
 */
function splitChain(cmd: string): string[] {
  return cmd
    .split(/\s*(?:&&|\|\||;)\s*/)
    .map((s) => s.trim())
    .filter(Boolean)
    .map((s) => s.split(/\s*\|\s*/)[0]?.trim() ?? "") // first pipe stage only
    .filter(Boolean);
}

/**
 * Reduce a segment to its canonical shape:
 *   "<binary>" or "<binary> <subcommand>"
 *
 * Returns "" for segments that don't look like shell commands (JS/Python
 * code fragments, empty heredoc artifacts, etc.).
 */
function normalize(segment: string): string {
  let s = segment.trim();
  if (!s) return "";

  // Drop leading env var assignments: KEY=val KEY2=val2 cmd ...
  s = s.replace(/^(?:[A-Z_][A-Z0-9_]*=\S*\s+)+/, "");

  // Drop leading path prefix from binary: /usr/bin/grep → grep, ./run → run
  s = s.replace(/^(?:\.?\/\S+\/)?/, "");

  const tokens = s.split(/\s+/);
  const rawBinary = tokens[0] ?? "";

  // Strip path from binary in case the replace above left residue
  const binary = rawBinary.replace(/^.*\//, "");

  // Must look like a real shell binary
  if (!BINARY_RE.test(binary)) return "";

  // Filter out language keywords / operators that end up here from -c scripts
  // Shell builtins + JS/TS/Python keywords that leak from -c scripts
  const NOISE = new Set([
    // shell builtins
    "if", "else", "then", "fi", "for", "do", "done", "while", "until",
    "case", "esac", "function", "return", "export", "local", "declare",
    "true", "false", "test", "source", ".", "eval", "exec", "trap",
    "read", "set", "unset", "shift", "continue", "break",
    // JS/TS keywords
    "const", "let", "var", "async", "await", "import", "export",
    "class", "new", "typeof", "instanceof", "throw", "try", "catch",
    "finally", "void", "yield", "delete", "in", "of",
    // Python keywords
    "def", "with", "pass", "raise", "lambda", "from", "assert",
    "not", "and", "or", "is", "elif",
    // noisy single-letter or empty
    "x", "v", "n", "s", "t", "i", "j", "k",
    // text fragments that pass BINARY_RE
    "text", "data", "args", "err", "out", "ok", "cmd", "msg",
    "result", "output", "input", "value", "values", "key", "keys",
    "type", "name", "path", "file", "dir", "url", "buf", "obj",
    "ctx", "req", "res", "err", "then", "next", "done", "end",
  ]);
  if (NOISE.has(binary.toLowerCase())) return "";

  // Optional subcommand: second token must be a plain bare word
  const rawSub = tokens[1] ?? "";
  const sub = SUBCMD_RE.test(rawSub) ? ` ${rawSub}` : "";

  return `${binary.toLowerCase()}${sub}`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const cutoffMs = Date.now() - LOOK_BACK_DAYS * 24 * 60 * 60 * 1000;
  const files = await findSessionFiles(cutoffMs);

  if (!files.length) {
    console.error(
      `No session files found in last ${LOOK_BACK_DAYS} days under ${SESSIONS_DIR}`,
    );
    process.exit(0);
  }

  // shape → { count, examples }
  const freq = new Map<string, { count: number; examples: string[] }>();

  for (const file of files) {
    let text: string;
    try {
      text = await readFile(file, "utf-8");
    } catch {
      continue;
    }

    for (const rawCmd of extractBashCommands(text)) {
      for (const segment of splitChain(rawCmd)) {
        const shape = normalize(segment);
        if (!shape) continue;

        const entry = freq.get(shape) ?? { count: 0, examples: [] };
        entry.count++;
        if (entry.examples.length < 3) {
          const trimmed = segment.replace(/\s+/g, " ").slice(0, 100);
          if (!entry.examples.includes(trimmed)) entry.examples.push(trimmed);
        }
        freq.set(shape, entry);
      }
    }
  }

  // Sort by count desc, then alpha
  const ranked = [...freq.entries()]
    .filter(([, v]) => v.count >= MIN_COUNT)
    .sort((a, b) => b[1].count - a[1].count || a[0].localeCompare(b[0]));

  if (OUTPUT_JSON) {
    console.log(
      JSON.stringify(
        ranked.map(([shape, { count, examples }]) => ({
          shape,
          count,
          examples,
        })),
        null,
        2,
      ),
    );
    return;
  }

  console.log(
    `\nBash pattern report — last ${LOOK_BACK_DAYS} days, ${files.length} session files\n`,
  );
  console.log(`${"shape".padEnd(28)} count  covered  candidate`);
  console.log("─".repeat(68));

  const candidates: Array<{
    shape: string;
    count: number;
    tool: string;
    reason: string;
    examples: string[];
  }> = [];

  for (const [shape, { count, examples }] of ranked) {
    const sample = examples[0] ?? shape;
    const covered = ALREADY_COVERED.some((re) => re.test(sample));
    const binary = shape.split(" ")[0]!;
    const nativeEntry = NATIVE_TOOL_MAP[binary] ?? NATIVE_TOOL_MAP[shape];
    const candidateTool = nativeEntry && !covered ? nativeEntry.tool : "";

    console.log(
      `${shape.padEnd(28)} ${String(count).padStart(5)}  ${covered ? "yes    " : "no     "}  ${candidateTool}`,
    );

    if (candidateTool && !covered) {
      candidates.push({
        shape,
        count,
        tool: candidateTool,
        reason: nativeEntry!.reason,
        examples,
      });
    }
  }

  console.log(
    `\n${files.length} session files scanned, ${freq.size} unique shapes`,
  );

  if (!EMIT_RULES) {
    if (candidates.length) {
      console.log(
        `${candidates.length} uncovered candidate(s) — re-run with --emit-rules for YAML snippets`,
      );
    }
    return;
  }

  if (!candidates.length) {
    console.log("\nNo new interceptor rule candidates found.");
    return;
  }

  console.log(`\n${"─".repeat(68)}`);
  console.log(
    "# Candidate bashInterceptor rules for ~/.omp/agent/config.yml\n",
  );
  console.log("bashInterceptor:");
  console.log("  enabled: true");
  console.log("  rules:");

  for (const { shape, count, tool, reason, examples } of candidates) {
    const binary = shape.split(" ")[0]!;
    const pattern = `(?:^|&&\\s*)(?:\\S+/)?${escapeRegex(binary)}\\b`;
    console.log(`    # "${shape}"  seen ${count}x`);
    if (examples[0]) console.log(`    # e.g.: ${examples[0]}`);
    console.log(`    - pattern: "${pattern}"`);
    console.log(`      tool: ${tool}`);
    console.log(`      message: "Prefer the ${tool} tool — ${reason}"`);
    console.log();
  }
}

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

await main();
