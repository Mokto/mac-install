---
ttsrTrigger: "\"op\"\\s*:\\s*\"pr_push\""
---
`pr_push` only works on branches checked out via `pr_checkout` — those carry push metadata.
For any branch you created locally (`git checkout -b`, `git switch -c`), use `git push` directly instead.
