import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// Process-lifetime cache: cwd → GHE host (or null for github.com / no remote).
// One git spawn per unique repo root, never repeated.
const cache = new Map<string, string | null>();

async function detectGheHost(cwd: string): Promise<string | null> {
  if (cache.has(cwd)) return cache.get(cwd)!;
  let host: string | null = null;
  try {
    const proc = Bun.spawn(["git", "remote", "get-url", "origin"], {
      cwd,
      stdout: "pipe",
      stderr: "pipe",
      stdin: "ignore",
    });
    const url = (await new Response(proc.stdout).text()).trim();
    await proc.exited;
    const match = url.match(/^(?:https?:\/\/|git@)([^/:]+)/);
    if (match && match[1] !== "github.com") host = match[1] ?? null;
  } catch {
    // Not a git repo or no remote.
  }
  cache.set(cwd, host);
  return host;
}

export default function ghHost(pi: ExtensionAPI) {
  // Set GH_HOST before each github tool call based on the session's origin
  // remote. gh CLI inherits process.env, so this routes all underlying gh
  // subprocess calls to the correct host with zero token cost.
  // Note: concurrent sessions on different hosts would race on process.env —
  // acceptable for the typical single-session workflow.
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "github") return;
    const host = await detectGheHost(ctx.cwd);
    if (host) process.env.GH_HOST = host;
    else delete process.env.GH_HOST;
  });
}
