# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.

## Entries

- 2026-10-05 | [decision] | repo | Renamed the default branch `master` to `main` locally and on `origin`, set the GitHub default to `main`, and retargeted the 16 doc references | `gh repo view --json defaultBranchRef` -> `main`

- 2026-10-05 | [trap] | models | `Year` hardcoded 54 weeks (378 days) and mis-seeded Monday January 1 as prior December 25, leaking an extra week into year-mode files | docs/specs/2026-10-05_YearBoundaryFullWeeks.md

- 2026-10-05 | [outcome] | models | Fixed `Year#days` to the full Monday/Sunday weeks intersecting the year: 371 days, 378 only for a leap year starting Sunday; added edge and 1900..2100 `Date` tests | src/models/year.rb:46

- 2026-10-05 | [outcome] | services | Shipped optional `birth_year` age rendering through `{{AGE}}`: added `BIRTH_YEAR`/`AGE` constants, `with_birth_year`/`template_includes?`, `test/birthday_age_config.yml`, a 9-example unit context, README Birthdays/Version History/TODO and glossary entries; full suite 321 examples 0 failures, rubocop 28 files 0 offenses; `test/test_config.yml` and e2e outputs unchanged | src/services/configured_tasks_service.rb:39; `bundle exec rspec`

- 2026-10-05 | [decision] | services | `birth_year` is an optional Integer task key valid only with `to_specific_date`; `{{AGE}}` renders build year minus birth year, resolved once in `ConfiguredTasksService#add_configured_tasks` before `resolve_template`; a non-Integer, nil, future, other-method, or `{{AGE}}`-less template raises `INVALID_CONFIG` | docs/specs/2026-10-05_BirthdayAgeFromBirthYear.md

- 2026-10-04 | [outcome] | services | Shipped optional `tag_order_config` root-tag ordering: 312 examples 0 failures, rubocop 28 files 0 offenses; `TagMergeService.order_roots` is 100% line/branch covered and the changed `src/` files are 100% except two pre-existing uncovered `tag_merge_service.rb` lines | test/spec/services/tag_merge_service_spec.rb; `RUBYOPT=-r/tmp/lb_cov.rb bundle exec rspec`

- 2026-10-04 | [decision] | services | `tag_order_config` is an ordered list, top first, with the reserved `~~OTHER~~` marker for unlisted tags; order runs after same-day merge, applies to root tags only, stable ties keep current order, and a missing marker puts unlisted tags after listed ones | docs/specs/2026-10-04_TagOrderConfig.md

- 2026-10-04 | [decision] | services | A configured root tag named `ConfigConstants::TAG_ORDER_MARKER` (`~~OTHER~~`) raises `INVALID_CONFIG` even with no `tag_order_config`, because the name is globally reserved | src/services/tag_merge_service.rb:19

- 2026-10-04 | [decision] | services | `to_each_day` now rejects any supplied `day_name` (valid or not) with `INVALID_DAY_NAME`, matching `to_each_weekday` and `to_each_weekend`; this breaks configs that passed the previously required `day_name` | src/services/add_task_service.rb:24

- 2026-10-04 | [trap] | test | The first `tag_order_config` order tests attached the bottom tag first, so insertion order already matched the expectation and they passed without the feature; reordered to attach the bottom tag last and added a no-order counterfactual | test/spec/services/add_task_service_spec.rb:1125

- 2026-10-04 | [outcome] | services | Fixed get_date_hash_from_do_file: the loop no longer hangs, slice! lengths are corrected, and malformed input (unterminated date line, missing, truncated, or misattributed block, CRLF) now raises ArgumentError instead of silently dropping days; replaced the dead commented-out does-not-hang stub with four real regression tests; full suite 283 examples 0 failures, rubocop 28 files 0 offenses | src/services/file_parser_service.rb:9; test/spec/services/file_parser_service_spec.rb:33

- 2026-10-04 | [decision] | test | Deleted the pending FileParser single-day example instead of enabling it: its stripped-fence expectation contradicted the fence-preserving two-day spec and the byte-identical e2e outputs, and single-day is not a separate code path; suite now 279 examples 0 failures 0 pending | src/services/file_parser_service.rb:33; test/spec/services/file_parser_service_spec.rb

- 2026-10-04 | [trap] | repo | An untracked generated personal log at the repo root (DO_2026_10.md, 1377 lines) was not covered by .gitignore, so git add -A would have committed it; added DO_*.md to .gitignore | .gitignore:8

- 2026-10-04 | [outcome] | services | Implemented to_each_weekday (Mon-Fri) and to_each_weekend (Sat-Sun) scheduling methods; both ignore odd_only/even_only and raise INVALID_DAY_NAME when the day_name key is present; added unit cases, an each_weekday_config.yml e2e context, and README supported-methods, examples, and Version History; full suite 279 examples 0 failures 0 pending after removing the stale pending case, rubocop 28 files 0 offenses | src/services/add_task_service.rb:30; test/e2e/e2e_spec.rb:192

- 2026-10-04 | [decision] | services | Added to_each_weekday and to_each_weekend as fixed-set methods reusing Year::WEEKDAY_DAY_NAMES and Year::WEEKEND_DAY_NAMES; no configurable day list, no month filters, no holiday exclusion, no method registry; e2e uses a new fixture rather than editing test_config.yml so the byte-identical characterization stays intact | docs/specs/2026-10-04_EachWeekdayScheduling.md

- 2026-10-04 | [outcome] | services | Fixed the merge render perf trap by deferring ConfigReaderService construction in TaskPrinterService#print_internal into the placeholder branch (it was built for every internal node); padded 154KB config with a daily internal task went 8.9s to 0.11s, full suite 3.77s to 0.80s, and a placeholder-bearing daily task stays 0.10s; also froze canonical children arrays and tightened the collision e2e to exact-match | src/services/task_printer_service.rb:44; src/services/tag_merge_service.rb:93

- 2026-10-04 | [trap] | services | TagMergeService.render builds a fresh TaskPrinterService per root and print_internal lazily YAML.load_file per printer, so a large config with a frequent internal task re-parses the file once per root per day; measured 8.9s vs ~0.04s pre-merge on a 154KB padded config with one to_each_day internal task; superseded 2026-10-04 | src/services/tag_merge_service.rb:65; src/services/task_printer_service.rb:43

- 2026-10-04 | [outcome] | services | Implemented same-day root tag merging per the spec: TagMergeService builds canonical trees and merges same-named roots recursively with incoming-first children and exact-leaf dedupe, rendering each root through a fresh TaskPrinterService; AddTaskService#attach keeps per-day tag_roots independent; four preexisting collision-day assertions in configured_tasks_service_spec were updated to post-merge output as the e2e note requires; full suite 259 examples 0 failures, rubocop 0 offenses | src/services/tag_merge_service.rb:1; test/spec/services/tag_merge_service_spec.rb:1

- 2026-10-04 | [decision] | services | Same-day root tags merge by exact name: incoming children prepended, recursive with exact-leaf dedupe, merged root keeps its bottom-most occurrence slot, internal beats leaf with the leaf kept as a child, always-on and silent; structured trees per day rendered through the existing printer | docs/specs/2026-10-04_MergeSameDayRootTags.md

- 2026-10-04 | [outcome] | repo | Corrected the history-leak premise: 7 subjects match the leak keywords (9 widened), not about 470; the author email spans 630 commits from 2017 to 2026 | `git log --all --grep=laundry --grep=gym --grep=rent --grep=billing --grep=appointment --format='%s'`; `git rev-list --all --count` -> 631
- 2026-10-04 | [outcome] | repo | Squash-merged the loop branch into `main` as one sentence-case commit and pushed; `agent-refactor` deleted local and remote | `git log --oneline -1 main` -> `59769f1`
- 2026-10-04 | [decision] | repo | Defer commit-history cleanup for now; no rewrite performed. Revisit with the critic findings: 7 leaking subjects, and the remote dependabot branch plus open PR #2 must be handled | docs/privacy/history-cleanup.md
- 2026-10-04 | [finding] | repo | Commit history exposes the author email (`efournier92@gmail.com`) on 630 commits and 7 routine-naming subjects; masking needs a rewrite, not done | `git log --all --format='%ae' | sort -u`
- 2026-10-04 | [outcome] | repo | Test expansion final: 216 examples, 0 failures, 1 pending; src coverage 99.43% line / 91.47% branch | `bundle exec rspec`; `RUBYOPT="-r/tmp/lb_cov.rb" bundle exec rspec`
- 2026-10-04 | [outcome] | services | Fixed `print_do_month` to filter by year and month | src/services/printer_service.rb:59
- 2026-10-04 | [trap] | services | `get_date_hash_from_do_file` passes an index as a `slice!` length and can hang when a date line has no trailing newline; superseded 2026-10-04 | src/services/file_parser_service.rb:13,30
- 2026-10-04 | [outcome] | services | Fixed `configured_template_by_name` with a nil guard on the missing section | src/services/config_reader_service.rb:24
- 2026-10-04 | [finding] | services | `return if tags.nil?` is unreachable because `configured_tasks` coerces a missing key to `{}` | src/services/configured_tasks_service.rb:14
- 2026-10-04 | [trap] | services | `{{TASK.*}}` composed templates are never resolved; exact lookup only, so they pass through literally | src/services/task_printer_service.rb:48
- 2026-10-04 | [outcome] | modules | Fixed `LogBuilder` to exit non-zero on an invalid config path | src/modules/log_builder.rb:21
- 2026-10-04 | [outcome] | docs | Genericized habit-revealing README tasks (rent, appointments, guitar, scrum) | README.md
- 2026-10-04 | [decision] | repo | Defer commit-history rewrite; owner runbook written instead of force-pushing now | docs/privacy/history-cleanup.md:1
- 2026-10-04 | [finding] | repo | `builds/` tracked two non-stripped binaries (about 150MB) and `tags` was tracked despite `.gitignore`; both untracked and squash-merged out of the tree, but the blobs remain in history | squashed into `59769f1`
- 2026-10-04 | [outcome] | test | Removed the unused `year: 1976` from `Birthday_Person`; `to_specific_date` never reads the key | test/test_config.yml:156
- 2026-10-04 | [finding] | repo | No live secrets in tracked text, configs, or sampled binary strings; only placeholder emails/phones | `git grep -nI -i -e password -e api_key -e token`
- 2026-10-04 | [outcome] | repo | Phase 1 sanitized the `README` mailbox and string brand and the machine path in the loop prompt; untracked generated artifacts | squashed into `59769f1`
- 2026-10-04 | [outcome] | services | `run.rb` now has an integration spec and the interactive prompts are covered via stdin stubs | test/spec/run_spec.rb; test/spec/modules/log_builder_spec.rb
- 2026-10-04 | [outcome] | repo | Phase 0 baseline: 105 examples, 0 failures, rubocop 0 offenses, src coverage 91.30% line / 72.09% branch | `bundle exec rspec`; `RUBYOPT="-r/tmp/lb_cov.rb" bundle exec rspec`
- 2026-10-04 | [decision] | repo | Commit messages used the agent Title Case convention; the loop commits were squashed into one sentence-case commit on `main`, so main history does not carry the tell | `git log -1 main --format=%s`
- 2026-10-04 | [decision] | repo | Hardening loop ran on `agent-refactor` with branch-local commits, then squash-merged to `main` and pushed; no mid-loop push | `git log --oneline -1 main`
- 2026-10-04 | [decision] | repo | Opt into Progressive Discovery; this index is committed and maintained by the hardening loop | docs/agent-prompts/hardening-loop.md:1
