import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const EXT_DIR = dirname(import.meta.path);
const PROMPT_PATH = join(EXT_DIR, "optimize-prompt.md");
const SCRIPT_PATH = join(homedir(), ".omp", "scripts", "optimize-report.ts");
const CHECKPOINT_PATH = join(homedir(), ".omp", "optimize-checkpoint");

const bunBin = Bun.which("bun") ?? "bun";

async function readCheckpoint(): Promise<number | null> {
  try {
    const text = await Bun.file(CHECKPOINT_PATH).text();
    const ms = new Date(text.trim()).getTime();
    return isNaN(ms) ? null : ms;
  } catch {
    return null;
  }
}

export default function optimize(pi: ExtensionAPI) {
  pi.registerCommand("optimize", {
    description: "Mine OMP sessions for optimization candidates",
    handler: async (cmdArgs, ctx) => {
      const checkpoint = await readCheckpoint();
      const label = checkpoint ? `since ${new Date(checkpoint).toLocaleString()}` : "last 30 days";
      ctx.ui.notify(`Running /optimize analysis (${label})…`, "info");

      try {
        const extra = cmdArgs.trim().split(/\s+/).filter(Boolean);
        const sinceArgs = checkpoint ? ["--since", String(checkpoint)] : [];
        const proc = Bun.spawn([bunBin, SCRIPT_PATH, ...sinceArgs, ...extra], {
          stdout: "pipe",
          stderr: "pipe",
          stdin: "ignore",
        });

        const [out, err] = await Promise.all([
          new Response(proc.stdout).text(),
          new Response(proc.stderr).text(),
        ]);
        const exitCode = await proc.exited;

        if (!out.trim() && !err.trim()) {
          const errMsg = `/optimize: script produced no output (exit ${exitCode}, bun=${bunBin}, script=${SCRIPT_PATH})`;
          ctx.ui.notify(errMsg, "error");
          pi.sendUserMessage(errMsg);
          await new Promise(r => setTimeout(r, 0));
          await ctx.waitForIdle();
          return;
        }

        const report = [out, err].map((s) => s.trim()).filter(Boolean).join("\n");
        const prompt = await Bun.file(PROMPT_PATH).text();
        const message = `${prompt.trim()}\n\n## Analyzer output\n\`\`\`\n${report}\n\`\`\``;
        pi.sendUserMessage(message);
        await new Promise(r => setTimeout(r, 0));
        await ctx.waitForIdle();
      } catch (e) {
        const errMsg = `/optimize error: ${e}`;
        ctx.ui.notify(errMsg, "error");
        pi.sendUserMessage(errMsg);
        await new Promise(r => setTimeout(r, 0));
        await ctx.waitForIdle();
      }
    },
  });

  pi.registerCommand("optimize-checkpoint", {
    description: "Mark now as the cutoff — future /optimize runs ignore sessions before this",
    handler: async (_args, ctx) => {
      const now = new Date();
      await Bun.write(CHECKPOINT_PATH, now.toISOString());
      const msg = `Checkpoint saved: ${now.toLocaleString()}. No action needed.`;
      ctx.ui.notify(msg, "info");
      pi.sendUserMessage(msg);
      await new Promise(r => setTimeout(r, 0));
      await ctx.waitForIdle();
    },
  });
}
