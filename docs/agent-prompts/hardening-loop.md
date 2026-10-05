# Autonomous Hardening Loop

Run one safe, autonomous loop on branch `agent-refactor`. You are the operator: dispatch specialists per the rulebook, verify every done claim, and keep decisions and handoffs yourself.

## Current State

- Repo: `<repo-root>`. Remote `origin` is the project GitHub remote.
- Branch: `agent-refactor` (pushed, tracking `origin/agent-refactor`). Default branch `main`.
- Stack: Ruby CLI, entry `src/run.rb`, Ruby 3.4.7. RSpec (`.rspec` sets `--default-path test`); RuboCop (`AllCops: NewCops: disable`).
- Baseline: `bundle exec rspec` = 105 examples, 0 failures. `bundle exec rubocop` = 0 offenses.
- Test hazard: `test/e2e/e2e_spec.rb` and `test/spec/modules/log_builder_spec.rb` write `./_out_test`. Run the suite serially, never in parallel.
- Known surfaces: `builds/` holds two tracked binaries (about 150MB total). `tags` is tracked yet already listed in `.gitignore`. Commit history carries the author email. README and `test/test_config.yml` contain habit-revealing specifics.
- Discovery: repo not yet opted in. This prompt opts it in. Create `docs/discovery/DISCOVERY.md` and log findings there.

## Mission

Meet all four goals in this loop.

- G1 Privacy: no private data about the author (identity, contact info, machine paths, routines, habits, possessions, work patterns) in tracked content, committed binaries, generated tags, or docs.
- G2 Quality: simplify, remove dead code, tighten error handling and hot paths. Minimal diffs only.
- G3 Human Voice: every change still reads as hand-written by the same author. No LLM tells.
- G4 Coverage: effectively every behavior and branch covered by unit and integration tests, including edge and corner cases. Uncovered paths that hide bugs get a failing test first.

## Autonomy Contract

Allowed without asking:

- Non destructive shell: read, grep, `git status/log/diff/show`, `ruby -c`, `bundle exec rspec`, `bundle exec rubocop`.
- Edit tracked source, tests, docs; create tests; create `docs/discovery/`; commit to `agent-refactor` using ship-changes message rules.
- Untrack generated artifacts while leaving them on disk.

Forbidden without explicit human sign off. Stop and report instead:

- `git push`, PR, merge, `git rebase`, `git commit --amend`, force push, any history rewrite.
- `git checkout --`, `git reset --hard`, `git restore`, `git stash drop`, `git clean -fd`, `rm -rf` outside `/tmp`.
- Deleting functionality, or changing public behavior without a test that pins current behavior first.
- Adding a runtime dependency. Dev only, only when required, and justified in the commit message.
- Handling a real live secret: never print or commit it. Stop immediately and report.

Budget: one pass through the phases, converge to green. If a phase cannot go green within its cap, log the blocker and move on instead of looping forever. All work lands on `agent-refactor`. Do not push.

## Phase 0 - Baseline And Behavior Map

Owner: `code-locator` (map), `verifier` (baseline).

- Confirm branch is `agent-refactor` and record `HEAD`.
- Run `bundle exec rspec` and `bundle exec rubocop --format simple`. Record exact counts.
- Enumerate every file under `src/` and `test/`. For each, map public methods, callers, and branches to `path:line`. Note which tests cover which behavior.
- Create `docs/discovery/DISCOVERY.md` with a header and one baseline entry.

Exit: baseline recorded. Every source file has a disposition (clean, changed, or finding). Module inventory returned.

## Phase 1 - Privacy Sweep

Owner: `compliance-officer` (triage), `code-locator` (locate), `external-researcher` (scanner availability), `builder` (remediate), `verifier` (prove).

Surfaces to cover:

- All tracked files, plus untracked and ignored files that could be committed later.
- `builds/*` binaries, which may embed source paths and strings. Inspect with `strings builds/* | rg`.
- `tags`, `test/test_config.yml`, `test/blank_config.yml`, README examples.
- Commit messages and author metadata via `git log --format='%an <%ae>%s'`.
- `.gitignore` gaps (`builds/`, `_out_test/`, `.ruby-lsp/`).

Hunt for: emails, phone numbers, addresses, absolute home paths, tokens, API keys, passwords, real names, employer or client names, and habit-revealing specifics (real schedule, possessions, routine).

Method: prefer `gitleaks` or `trufflehog` if installed, else `ripgrep` patterns. Do not trust a tool alone. Classify every match as SECRET, PII, HABIT, PATH, or SAFE.

Remediate:

- Replace with obvious placeholders: `user@example.com`, `Jane_Doe`, `555-0100`, `123 Example St`, `/path/to/...`.
- Genericize habit-revealing README and config examples while keeping them functional. Update dependent tests.
- Untrack `builds/` and `tags` (keep files on disk). Add missing `.gitignore` entries.
- Real live secret: stop, report, do not commit, do not print.

History: report only. Never rewrite. Note the retained binaries and author email as residual risk.

Exit: no classified findings remain in tracked content. Verifier confirms. Discovery entries written.

## Phase 2 - Coverage Map

Owner: `code-locator` (map), `verifier` (measure).

- Measure line and branch coverage for `src/` using Ruby stdlib `Coverage`. Prefer it over a new gem. Add `simplecov` only if stdlib proves insufficient, dev only.
- Enumerate every public method and branch, mark covered or GAP. Treat README-documented behaviors as integration-test targets, including the CLI argument matrix in `src/run.rb`.

Exit: a risk-prioritized gap list, written to `DISCOVERY.md`.

## Phase 3 - Test First Hardening

Owner: `builder` (write), `verifier` (prove).

For each gap, write a characterization test that pins current behavior, then edge and corner cases.

Known bug leads to turn into tests:

- `print_do_month` filters only by month, so prior-year December back fill leaks into a December file.
- `FileParser#get_date_hash_from_do_file` slicing and loop termination on a trailing date line.
- `AddTaskService` mutating the caller's shared config hash.
- Prompt loops on stdin EOF in `LogBuilder#collect_user_input`.
- `Year` hard coded `54.times` day count versus a real year.
- `log_builder_spec` "without a month" case that actually passes a month, leaving `print_do_year` untested.

Edge cases: nil and empty input, leap year, year and month rollover, month end, malformed or blank YAML, missing file, unknown mode or day name, duplicate tags.

If a test reveals a bug: keep the failing test, mark it, log the bug, then fix only if the fix is safe and fully covered. Never silently change behavior.

Exit: coverage bar met (target line at least 95 percent, branch at least 90 percent for `src/`), suite green.

## Phase 4 - Quality Refactor

Owner: `builder` with `simplify-code`, reviewed by `claim-critic`.

- Apply only changes pinned by Phase 3 tests: dead code, duplication, error handling, hot paths.
- No new abstraction for a single use. No mass reformatting. Shortest working diff.

Exit: suite and rubocop green. Diffs minimal.

## Phase 5 - Human Voice Audit

Owner: `claim-critic` (LLM-tell red team), `context-curator` (markdown style), `builder` (flatten).

Hunt for LLM artifacts in code, comments, commit messages, and docs: over explanation, uniform verbosity, emoji, em dashes, filler ("It is worth noting", "comprehensive", "robust", "leverage", "seamless"), class-level doc comments that did not exist before, gratuitous helper methods.

Match the author's idiom: keep terse comments and `# TODO:` markers, keep existing naming and quirks unless they hide a bug.

Run the rulebook markdown style checks on any Markdown touched.

Exit: no flagged artifacts remain.

## Phase 6 - Verify And Handoff

Owner: `verifier` (final proof), `claim-critic` (handoff red team), `write-handoff`, `log-discoveries`.

Prove all at once:

- `bundle exec rspec` green.
- `bundle exec rubocop --format simple` clean.
- Coverage bar met.
- Privacy scan returns no classified findings in tracked content.
- `git status` shows only intended changes.

Then reconcile `DISCOVERY.md`, write the session handoff, and produce the final report. Do not push.

## Routing Table

| Work | Agent or skill |
| --- | --- |
| Map code, callers, `path:line` | `code-locator` |
| Prove a done claim, run checks | `verifier` |
| Red-team handoffs, diffs, LLM-tell pass | `claim-critic` |
| Privacy and regulatory pre-filter | `compliance-officer` |
| External tool or version facts | `external-researcher` |
| Implement changes and tests | `builder` |
| Remove over-engineering | `simplify-code` |
| Keep docs, memory, handoffs lean | `context-curator` |
| Durable findings | `log-discoveries` |
| End of loop write-up | `write-handoff` |
| Prose cleanup | `wordsmith` or `phraser` |

## Living Docs

`docs/discovery/DISCOVERY.md` is the durable index for this repo. Append proven findings, decisions, traps, and outcomes as they land. One line each, newest first, tagged `[finding]`, `[trap]`, `[decision]`, or `[outcome]`, with evidence (`path:line`, URL, or exact command). Unproven items get `[assumption]`. Reconcile at the end.

Durable decisions and preferences also go to the auto-memory index. Do not store what version control or project docs already record.

## Final Report

- G1 to G4 status: met or not, with evidence.
- Findings: severity, `path:line`, and the command that proved each.
- Coverage delta: before and after, per metric.
- Bugs surfaced, each with its failing test.
- Residual risk: history-retained binaries, author email, and anything unverifiable.
- Human-voice self-audit: what was flagged and flattened.
- Open items and the exact next step (open the PR).

## Stop Conditions

Stop and report when all phases are green, when the turn budget is hit, or when a forbidden action would be required. Never push.
