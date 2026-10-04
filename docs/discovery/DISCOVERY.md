# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.

## Entries

- 2026-10-04 | [outcome] | docs | Sanitized tracked docs: removed the local path and GitHub handle from the loop prompt; privacy scan is clean | `git grep -nI -E '/Users/|efournier92'`
- 2026-10-04 | [decision] | repo | Commit messages use the agent Title Case convention, unlike the author sentence case; flagged, left until a branch-history rewrite is approved | `git log master..agent-refactor --format=%s`
- 2026-10-04 | [outcome] | repo | Test expansion: 217 examples 0 failures 5 pending; src coverage 99.43% line / 91.47% branch | `bundle exec rspec`; `RUBYOPT="-r/tmp/lb_cov.rb" bundle exec rspec`
- 2026-10-04 | [outcome] | services | Fixed `print_do_month` to filter by year and month | src/services/printer_service.rb:59
- 2026-10-04 | [trap] | services | `get_date_hash_from_do_file` passes an index as a `slice!` length and can hang when a date line has no trailing newline | src/services/file_parser_service.rb:13,30
- 2026-10-04 | [outcome] | services | Fixed `configured_template_by_name` with a nil guard on the missing section | src/services/config_reader_service.rb:24
- 2026-10-04 | [finding] | services | `return if tags.nil?` is unreachable because `configured_tasks` coerces a missing key to `{}` | src/services/configured_tasks_service.rb:14
- 2026-10-04 | [trap] | services | `{{TASK.*}}` composed templates are never resolved; exact lookup only, so they pass through literally | src/services/task_printer_service.rb:48
- 2026-10-04 | [outcome] | modules | Fixed `LogBuilder` to exit non-zero on an invalid config path | src/modules/log_builder.rb:21
- 2026-10-04 | [outcome] | docs | Genericized habit-revealing README tasks (rent, appointments, guitar, scrum) | README.md
- 2026-10-04 | [decision] | repo | Defer commit-history rewrite; owner runbook written instead of force-pushing now | docs/privacy/history-cleanup.md:1
- 2026-10-04 | [trap] | repo | Commit history exposes author email and about 470 habit-revealing subjects (laundry, gym, rent, billing); only a history rewrite removes it, not done | `git log --format='%s'`; `git log --format='%ae' | sort -u`
- 2026-10-04 | [finding] | repo | `builds/` tracked two non-stripped binaries (about 150MB) and `tags` was tracked despite `.gitignore`; both untracked, but blobs remain in history | commit 720085f
- 2026-10-04 | [outcome] | test | Removed the unused `year: 1976` from `Birthday_Person`; `to_specific_date` never reads the key | test/test_config.yml:156
- 2026-10-04 | [finding] | repo | No live secrets in tracked text, configs, or sampled binary strings; only placeholder emails/phones | `git grep -nI -i -E 'password|api_key|token'`
- 2026-10-04 | [outcome] | repo | Phase 1 sanitized `README` mailbox/string-brand and the machine path in the loop prompt; untracked generated artifacts | commit b903b8f
- 2026-10-04 | [outcome] | repo | Phase 0 baseline: 105 examples 0 failures, rubocop 0 offenses, src coverage 91.30% line / 72.09% branch | `bundle exec rspec`; `RUBYOPT="-r/tmp/lb_cov.rb" bundle exec rspec`
- 2026-10-04 | [trap] | services | `src/run.rb` is required by no spec and contributes 0 to coverage; CLI matrix effectively unverified | verifier Phase 0
- 2026-10-04 | [trap] | services | `print_do_month` filters `day.month` only, so prior-year December back fill leaks into a month file | src/services/printer_service.rb:59
- 2026-10-04 | [trap] | services | `FileParser#get_date_hash_from_do_file` passes an index as a `slice!` length and can spin when a date line has no trailing newline | src/services/file_parser_service.rb:22,30
- 2026-10-04 | [trap] | services | `task_printer_service` nil branches and `{{TASK.*}}` resolution are untested | src/services/task_printer_service.rb:163,168
- 2026-10-04 | [decision] | repo | Opt into Progressive Discovery; this index is committed and maintained by the hardening loop | docs/agent-prompts/hardening-loop.md:1
- 2026-10-04 | [decision] | repo | Hardening loop runs on branch `agent-refactor`, branch-local commits only, never pushes | docs/agent-prompts/hardening-loop.md:1
