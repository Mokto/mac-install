---
ttsrTrigger: "\"op\"\\s*:\\s*\"run_watch\""
---
`run_watch` requires either `branch` or `run` to be specified — especially on GHE repos.
Without one, it cannot infer the watched commit and will abort.
Always pass `branch: "your-branch-name"` or `run: <run-id>`.
