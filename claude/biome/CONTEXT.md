# Biome Contributor Custom Instructions

Synthesized from human reviewer feedback (ematipico, dyc3) on PRs from Mokto in the biomejs/biome repository. Use this document before writing or reviewing any code contribution to biome.

**Before writing a new lint rule, read the official contribution guide in full:**
- Rule implementation: `crates/biome_analyze/CONTRIBUTING.md`
- Rule pillars (diagnostic structure): https://biomejs.dev/linter/#rule-pillars

A reviewer flagged that an entire first rule submission had many things that didn't follow the guide. Do not skip reading it.

---

## 1. Changeset Format

- **Bug fixes**: Start the description with `Fixed [\`#NUMBER\`](issue link): ...` — only when a corresponding GitHub issue exists. If no issue exists, use a plain free-form description.
- **New rules**: Start with `Added the new nursery rule [\`ruleName\`](https://biomejs.dev/linter/rules/rule-name/), ...`
- **Every sentence must end with a full stop (`.`)**. Never end a sentence in a changeset with a colon.
- **Version bump**: Use `patch` for bug fixes and new nursery rules (targets `main`). Use `minor` only when promoting a rule from nursery to a stable group (targets `next`). Use `major` for breaking changes (targets `next`).
- **Rule links**: When referencing a lint rule by name, always link it: `[\`noUnusedImports\`](https://biomejs.dev/linter/rules/no-unused-imports/)`.
- **New rules must include invalid examples** in the changeset — at least one inline code snippet per rule showing a violation.
- **Parser changes**: When a PR includes a parser improvement, show a brief "Can now parse" example if the change has a direct user-visible effect on what syntax is accepted.
- **Keep changesets concise**: 1–3 sentences. Remove technical internals; focus on the user-visible effect. Avoid LLM-verbose language. Do not expose implementation details like struct names or internal module paths.
- **One rule per changeset**: If a PR ships multiple rules, create a separate changeset file for each rule.

---

## 2. Rule Naming Conventions

- Use the full-word spelling: `noDuplicate<Concept>`, not `noDupe<Concept>`. Example: `noDuplicateElseIf`, not `noDupeElseIfBlocks`.
- When a JS rule already exists with a given name (e.g. `noDuplicateElseIf`), the HTML/Svelte equivalent rule for the same concept should reuse the same name, not add a language prefix unless the behavior is language-specific (e.g. `noSvelteDuplicateStyleProperties` is appropriate because `style:` directives are Svelte-specific).
- Biome rule names should be cross-language when the underlying concept is language-agnostic. Document in the rule that it currently only applies to Svelte (or the relevant subset).
- Avoid redundant prefixes in rule names: `noSvelteUnnecessaryStateWrap` not `noSvelteNoUnnecessaryStateWrap` — do not double the negation.
- When porting an ESLint rule, Biome's naming convention inserts the framework name after the leading verb: `svelte/require-each-key` → `useSvelteRequireEachKey`.
- After renaming a rule, always re-run `just gen-rules` and `just gen-configuration` to regenerate rule metadata and configuration.

---

## 3. Rule Diagnostics — The Three Pillars

Every `RuleDiagnostic` must cover three things:

1. **What is the error** — describe the problem in the first message.
2. **Why it is an error** — explain the consequence or reason (e.g. "this branch can never execute").
3. **How to fix it** — add a `.note()` or `.help()` telling the user what action to take (e.g. "Remove the duplicate directive.").

A diagnostic that only covers the "what" and "why" but omits the fix instruction is incomplete. See the [rule pillars docs](https://biomejs.dev/linter/#rule-pillars).

---

## 4. Rule Implementation

- **Rule metadata `version` field**: New rules must use `"next"` as the version.
- **Options documentation — do not skip this**: Before opening a PR with a rule that has options, open `crates/biome_analyze/CONTRIBUTING.md` and follow it exactly. Every option needs: a rustdoc comment, a default-value statement, a JSON block showing all options and their defaults, and at least one code example using `use_options` or `expect_diagnostic`. Submitting a rule with options that don't follow this guide will result in a `CHANGES_REQUESTED` review. Read the guide. Do not guess.
- **Options struct**: Always add a `///` rustdoc comment above options structs, even if they are empty. Example: `/// Options for the noFooBar rule. This rule currently has no configurable options.`
- **Defaults idiom**: Use `.unwrap_or_default()` rather than manual boolean checks. Example: `if options.allow_reassign.unwrap_or_default()`.
- **`fix_kind`**: If a rule provides a code action, declare `fix_kind: FixKind::Safe` or `fix_kind: FixKind::Unsafe` in `declare_lint_rule!`.
- **Rule source**: When porting from ESLint or another linter, declare it with `sources` metadata using `RuleSource::Eslint(...)`.
- **Avoid putting multiple new rules in a single PR**. One rule per PR is strongly preferred.
- **Do not put analysis logic in the `run` function** that belongs in the `action` function. Specifically, node lookups used only for code actions should live in the action function.
- **Use `ok()?` instead of `let ... else`** where idiomatic.
- **Use `match` instead of if/else chains** when dispatching on AST node variants — the compiler will catch missing arms when new variants are added.
- **Use `AnySvelteDirective`** (or equivalent enum types) to match all directive variants at once rather than manually listing each arm.

---

## 5. Parser Architecture

- **Lookahead belongs in the parser, not the lexer**. If a fix requires lookahead, implement it via the parser's existing `p.lookahead` function. Do not add speculative scanning to the lexer.
- **The grammar (`.ungram` file) is the source of truth**. Do not add comments in generated or handwritten parser code that merely restate the grammar — those comments do not add value.
- **Malformed input recovery**: When a parser loop encounters a token it cannot consume (e.g. `{` that `parse_single_text_expression` returns `Absent` for), consume or recover that token into the current node rather than breaking the loop and leaving the token in the stream. Leaking tokens causes subsequent parse passes to misinterpret them.
- **Template string parsing in lint rules**: Do not re-parse or scan string values at the analysis level when the parser has already produced structured nodes. Emit a proper AST node (e.g. `SvelteInterpolatedString`) in the parser instead of doing string scanning in the analyzer.
- **Use existing helpers**: Before writing new string/value extraction code, check whether a helper like `string_value()` already exists on the relevant type. For example, `AnyHtmlAttributeInitializer::string_value()` returns `None` when a Svelte interpolation is present, which is exactly what rules checking static string content need.

---

## 6. Domain and Architecture

- **Svelte rules should live in the Svelte domain**. When adding a Svelte-specific rule, ensure it is registered in the `svelte` rule domain, not just the generic HTML domain.
- **Element name comparisons must be case-aware**: In `.html` files, comparisons against element name lists (e.g. INTERACTIVE_ELEMENTS) can be case-insensitive. In `.svelte`, `.vue`, and `.astro` files, comparisons must be case-sensitive because PascalCase names denote custom components.
- **CLI integration tests**: Avoid adding CLI-level integration tests for things that can be covered by the analyzer's own test infrastructure. The analyzer already supports Svelte/Vue/Astro; use spec-based tests there instead.
- **EmbeddedValueReferences**: Template references are collected as raw token text because there is no shared semantic model across embedded-snippet boundaries (script block vs. template). Symbol-aware matching across the boundary requires a unified semantic model that does not yet exist; do not attempt it in individual rules.

---

## 7. Snapshot Tests

- After adding or modifying rules, run the tests and **accept snapshots with `cargo insta accept`** before committing. Do not commit `.snap.new` files — they are pending insta artifacts and will break CI.
- All rule spec tests require `invalid` and `valid` fixture files under `crates/biome_<lang>_analyze/tests/specs/{group}/{ruleName}/`.
- **Invalid fixtures**: Each code snippet in an `invalid` fixture that expects a diagnostic must use the `expect_diagnostic` block property, and must emit exactly one diagnostic per snippet.
- **Valid fixtures**: Must not emit any diagnostics.
- **Bug fix tests**: Formatter bug fixes should include HTML formatter tests; they automatically check re-formatting idempotency.
- Snapshot tests for rule source (`RuleSource`) and ESLint migration mappings are code-generated and do not need manual snapshot tests.

---

## 8. Code Quality and Comments

- **Comments that describe what the code does are usually superfluous** — remove them. A comment is valuable when it explains *why* something is done a particular way, especially non-obvious design decisions or constraints.
- **Do not use LLM-generated verbose comments**. Write comments yourself. If a design decision needs documenting (e.g. a limitation of the cross-language architecture), write a concise plain-language comment stating what the constraint is and why.
- **Use `TokenText` over `String`** when storing text from AST tokens to avoid unnecessary heap allocations.
- **Prefer iterators over manual loops**: Use `.iter().chain(...).any(...)` rather than `.contains()` on separate collections.
- **`skip(1)`**: When traversing ancestor nodes looking for a parent of a specific type, remember to call `.skip(1)` to skip the current node itself.
- **Never commit `.claude/` files to the biome repo**: Claude Code creates a `.claude/projects/` directory with memory and transcript files. These must never be staged or committed. Add `.claude/` to `.gitignore` in the biome worktree, or double-check `git diff --staged` before every commit.
- **Avoid worktree files in commits**: Remove any `.worktree` files or other IDE-generated artifacts before opening a PR.
- **Clean commits**: Be careful about what you include in commits. Only stage files directly relevant to the change.

---

## 9. PR Hygiene

- **Always fill out the PR template** completely. Do not delete it or leave sections blank.
- **Link the related issue** in the changeset and in the PR description when one exists.
- **Add a Biome playground link** in the PR description when the change affects parsing or formatting behavior — this allows reviewers to verify the fix interactively.
- **Keep PRs focused**: One logical change per PR. Large PRs with multiple independent bug fixes are difficult to review and delay merging.
- **New nursery rules target `main`**; rule promotions from nursery to a stable group target `next`.

---

## 10. Svelte-Specific Notes

- Svelte `on:` event directives (e.g. `on:click={...}`) are old Svelte 3/4 syntax and are **intentionally unsupported** by Biome. Svelte 5 runes mode uses regular attributes for event handlers. Do not flag missing handling of `on:` directives.
- Svelte `{#each}` binding syntax: `as const` in the collection expression is a TypeScript expression, not Svelte-specific syntax. Comments referencing this should describe it as a TypeScript `as const` assertion, not a Svelte feature.
- When adding tests for Svelte interpolation in lint rules, always include an **error test** (e.g. a case where a referenced variable is undefined) in addition to valid cases.
