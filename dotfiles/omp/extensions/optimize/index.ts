import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { dirname, join } from "node:path";

const PROMPT_PATH = join(dirname(import.meta.path), "optimize-prompt.md");

export default function optimize(pi: ExtensionAPI) {
  pi.registerCommand("optimize", {
    description: "Mine OMP sessions for optimization candidates",
    handler: async (cmdArgs, ctx) => {
      const content = await Bun.file(PROMPT_PATH).text();
      const extra = cmdArgs.trim();
      const message = extra ? `${content.trim()}\n\n---\n\nUser: ${extra}` : content.trim();
      pi.sendUserMessage(message);
      ctx.ui.notify("Running /optimize analysis…", "info");
    },
  });
}
