---
ttsrTrigger: "\"op\"\\s*:\\s*\"pr_create\""
---
Before calling `pr_create`, the branch must exist on the remote.
Push it first: `git push` or `git push -u origin <branch>`.
Calling `pr_create` on an unpushed branch fails with "must first push the current branch to a remote".
