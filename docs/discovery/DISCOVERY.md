# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.

## Entries

- 2026-10-04 | [outcome] | repo | Corrected the history-leak premise: 7 subjects match the leak keywords (9 widened), not about 470; the author email spans 630 commits from 2017 to 2026 | `git log --all --grep=laundry --grep=gym --grep=rent --grep=billing --grep=appointment --format='%s'`; `git rev-list --all --count` -> 631
- 2026-10-04 | [outcome] | repo | Squash-merged the loop branch into `master` as one sentence-case commit and pushed; `agent-refactor` deleted local and remote | `git log --oneline -1 master` -> `59769f1`
- 2026-10-04 | [decision] | repo | Defer commit-history cleanup for now; no rewrite performed. Revisit with the critic findings: 7 leaking subjects, and the remote dependabot branch plus open PR #2 must be handled | docs/privacy/history-cleanup.md
- 2026-10-04 | [finding] | repo | Commit history exposes the author email (`efournier92@gmail.com`) on 630 commits and 7 routine-naming subjects; masking needs a rewrite, not done | `git log --all --format='%ae' | sort -u`
- 2026-10-04 | [outcome] | repo | Test expansion final: 216 examples, 0 failures, 1 pending; src coverage 99.43% line / 91.47% branch | `bundle exec rspec`; `RUBYOPT="-r/tmp/lb_cov.rb" bundle exec rspec`
- 2026-10-04 | [outcome] | services | Fixed `print_do_month` to filter by year and month | src/services/printer_service.rb:59
- 2026-10-04 | [trap] | services | `get_date_hash_from_do_file` passes an index as a `slice!` length and can hang when a date line has no trailing newline | src/services/file_parser_service.rb:13,30
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
- 2026-10-04 | [decision] | repo | Commit messages used the agent Title Case convention; the loop commits were squashed into one sentence-case commit on `master`, so master history does not carry the tell | `git log -1 master --format=%s`
- 2026-10-04 | [decision] | repo | Hardening loop ran on `agent-refactor` with branch-local commits, then squash-merged to `master` and pushed; no mid-loop push | `git log --oneline -1 master`
- 2026-10-04 | [decision] | repo | Opt into Progressive Discovery; this index is committed and maintained by the hardening loop | docs/agent-prompts/hardening-loop.md:1
