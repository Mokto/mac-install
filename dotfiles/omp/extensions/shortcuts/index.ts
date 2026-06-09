import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

export default function shortcuts(pi: ExtensionAPI) {
  // pi.registerCommand("sonnet", {
  //   description: "Switch to claude-sonnet-4-6",
  //   handler: async (_args, ctx) => {
  //     await pi.setModel("claude-sonnet-4-6");
  //     ctx.ui.notify("claude-sonnet-4-6", "info");
  //   },
  // });
  // pi.registerCommand("opus", {
  //   description: "Switch to claude-opus-4-8",
  //   handler: async (_args, ctx) => {
  //     await pi.setModel("claude-opus-4-8");
  //     ctx.ui.notify("claude-opus-4-8", "info");
  //   },
  // });
  // pi.registerCommand("composer", {
  //   description: "Switch to cursor/composer-2.5",
  //   handler: async (_args, ctx) => {
  //     await pi.setModel("cursor/composer-2.5");
  //     ctx.ui.notify("cursor/composer-2.5", "info");
  //   },
  // });
}
