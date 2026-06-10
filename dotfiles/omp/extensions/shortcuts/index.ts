import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

export default function shortcuts(pi: ExtensionAPI) {
  pi.registerCommand("pr", {
    description:
      "Push current branch and open a pull request (args forwarded to agent)",
    handler: async (cmdArgs, ctx) => {
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
      const { promise, resolve } = Promise.withResolvers<void>();
      setTimeout(resolve, 0);
      await promise;
      await ctx.waitForIdle();
    },
  });
}
