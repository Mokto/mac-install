import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

/**
 * Detect a non-github.com remote host from the git config in `cwd`.
 * Returns the hostname (e.g. "ocean.ghe.com") or null if it's github.com or
 * there's no git remote.
 */
async function detectGheHost(cwd: string): Promise<string | null> {
  try {
    const proc = Bun.spawn(["git", "remote", "get-url", "origin"], {
      cwd,
      stdout: "pipe",
      stderr: "pipe",
      stdin: "ignore",
    });
    const url = (await new Response(proc.stdout).text()).trim();
    await proc.exited;
    // Matches https://HOST/... and git@HOST:...
    const match = url.match(/^(?:https?:\/\/|git@)([^/:]+)/);
    if (match) {
      const host = match[1];
      if (host && host !== "github.com") return host;
    }
  } catch {
    // Not a git repo, no remote, or git not available — ignore silently.
  }
  return null;
}

export default function shortcuts(pi: ExtensionAPI) {
  // Inject a GHE context note before the first agent turn when the repo's
  // origin remote is not on github.com. Eliminates the "GraphQL 404 / wrong
  // host" error class where the agent calls the github tool without knowing
  // it needs to route through a GHE endpoint.
  pi.on("session_start", async (_event, ctx) => {
    const host = await detectGheHost(ctx.cwd);
    if (!host) return;
    pi.sendUserMessage(
      `[repo context] This repository's \`origin\` remote is hosted on **${host}** ` +
        `(GitHub Enterprise), not github.com. ` +
        `The \`github\` tool routes through \`gh\` CLI which is authenticated for ${host} — ` +
        `it will work correctly as long as you derive \`repo\` from the actual remote ` +
        `(e.g. via \`gh repo view --json nameWithOwner\`) rather than guessing. ` +
        `Do not hardcode \`github.com\` URLs or assume public GitHub API endpoints.`,
      { deliverAs: "nextTurn" },
    );
  });

  pi.registerCommand("pr", {
    description:
      "Push current branch and open a pull request (args forwarded to agent)",
    handler: async (cmdArgs, ctx) => {
      // Push first — eliminates the github-push-before-pr-create TTSR rule firing.
      ctx.ui.notify("Pushing branch…", "info");
      const pushProc = Bun.spawn(
        ["git", "push", "--set-upstream", "origin", "HEAD"],
        {
          cwd: ctx.cwd,
          stdout: "pipe",
          stderr: "pipe",
          stdin: "ignore",
        },
      );
      const [pushOut, pushErr] = await Promise.all([
        new Response(pushProc.stdout).text(),
        new Response(pushProc.stderr).text(),
      ]);
      const pushExit = await pushProc.exited;

      const extra = cmdArgs.trim();
      const msg =
        pushExit === 0
          ? `create pr${extra ? " " + extra : ""}`
          : `/pr: push failed (exit ${pushExit})\n${(pushErr || pushOut).trim()}`;

      pi.sendUserMessage(msg);
      await new Promise((r) => setTimeout(r, 0));
      await ctx.waitForIdle();
    },
  });
}
