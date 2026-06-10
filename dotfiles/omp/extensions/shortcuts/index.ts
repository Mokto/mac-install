import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

export default function shortcuts(pi: ExtensionAPI) {
  pi.registerCommand("pr", {
    description:
      "Push current branch and open a pull request (args forwarded to agent)",
    handler: async (cmdArgs, ctx) => {
      // Push first — eliminates the github-push-before-pr-create TTSR rule firing.
      ctx.ui.notify("Pushing branch…", "info");
      const pushProc = Bun.spawn(
        ["git", "push", "--set-upstream", "origin", "HEAD"],
        {
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
