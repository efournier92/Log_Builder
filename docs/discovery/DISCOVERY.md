# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.
Scope tokens: build, cli, models, repo, services, test

## Entries

- D-20261009-01 | 2026-10-09 | [decision] | repo | Keep README Version History canonical (releases mirror it) and gate it in build_spec: CI fails until the VERSION bump ships a matching heading | test/spec/build_spec.rb:138
- D-20261009-02 | 2026-10-09 | [outcome] | repo | Backfilled Releases v2024.04.11, v2024.05.01, v2026.10.05, v2026.10.08 with backdated tags (tagger date sets created_at) and matching builds assets; buildless skipped | `gh release list`
- D-20261009-03 | 2026-10-09 | [trap] | repo | Evidence path tokens are ignored unless they end in a listed extension; a Ruby source path must carry a :line to count as external evidence | scripts/check_discovery.py:23
- D-20261008-01 | 2026-10-08 | [decision] | repo | Tag and Release start now (`vYYYY.MM.DD` at the merge commit, asset = snapshot); the deferred history rewrite re-creates the tag/Release at the rewritten commit | README.md:144
- D-20261008-02 | 2026-10-08 | [trap] | services | Trailing-slash output dir doubled (`Wrote .//DO_...md`) and an empty `output_dir` raised raw `Errno::ENOENT`; fixed via `File.join` | src/services/printer_service.rb:4
- D-20261008-03 | 2026-10-08 | [trap] | services | All-leaf child lists were flattened, so an inline `{{Template}}` among leaves never expanded; removing the flatten fixed resolution | src/services/tag_merge_service.rb:104
- D-20261008-04 | 2026-10-08 | [outcome] | build | Added a `build_spec` example asserting `src/**/*.rb` equals `SOURCE_ORDER`, closing a gap where a new `src/` file could ship absent from the Bundle | test/spec/build_spec.rb:70
- D-20261008-05 | 2026-10-08 | [outcome] | repo | Exec-bit trap root-caused: `core.filemode=false` hid modes; added `executable_modes_spec.rb` plus CI, reset README and `src/run.rb` to `644` | `git ls-files -s README.md`
- D-20261008-06 | 2026-10-08 | [decision] | repo | Install captured in `bin/install`: installs the newest `builds/log-builder_*` as `log-builder`, rejects a shebang-less build, prints `PATH` hints | `git ls-files -s bin/install`
- D-20261008-07 | 2026-10-08 | [trap] | services | A null or non-String/Hash/Array `template` validated clean and attached nothing at exit 0; now rejected with a named-template message | src/services/config_reader_service.rb:390
- D-20261008-08 | 2026-10-08 | [trap] | services | Duplicate detection compared only `key.value`, so YAML `1:` and `"1":` were false duplicates; identity now includes `key.plain` | src/services/config_reader_service.rb:144
- D-20261008-09 | 2026-10-08 | [trap] | services | A list `base` with a per-day String passed LG validation, then `template_base + day_config` raised raw `TypeError`; now matched by class at load | src/services/config_reader_service.rb:251
- D-20261008-10 | 2026-10-08 | [outcome] | services | Critic hardening: null-template guard, quoted/plain duplicate fix, mixed LG type check, tag-source first-writer, `Wrote File > <path>` echo | src/services/printer_service.rb:96
- D-20261008-11 | 2026-10-08 | [outcome] | services | Hardened validation: atomic writes, load-time placeholder checks, root/section guards, file and line numbers, `day`/`birth_year`/`tag_order` in `validate!` | test/spec/run_spec.rb:83
- D-20261008-12 | 2026-10-08 | [outcome] | services | Load validation shipped | docs/specs/2026-10-08_ConfigLoadValidation.md
- D-20261008-13 | 2026-10-08 | [trap] | build | `build_spec.rb:97` compares the fresh Bundle to the newest git-tracked `builds/log-builder_*`; any `src/` change fails it until the new snapshot is committed | test/spec/build_spec.rb:97
- D-20261008-14 | 2026-10-08 | [decision] | services | Config load validation approved | docs/specs/2026-10-08_ConfigLoadValidation.md
- D-20261008-15 | 2026-10-08 | [decision] | services | String-missing-template fallback superseded | docs/specs/2026-10-08_ConfigLoadValidation.md
- D-20261008-16 | 2026-10-08 | [outcome] | build | Build critique fixes: exec bit and snapshot | `bundle exec rspec`
- D-20261008-17 | 2026-10-08 | [trap] | build | build.rb committed without exec bit | `git ls-files -s build.rb`
- D-20261005-01 | 2026-10-05 | [outcome] | build | Single-file build implemented | `/usr/bin/ruby -c builds/log-builder_2026-10-05`
- D-20261005-02 | 2026-10-05 | [trap] | services | Ruby 3.1 hash omission broke the 2.6 floor | `/usr/bin/ruby -c builds/log-builder_2026-10-05`
- D-20261005-03 | 2026-10-05 | [trap] | build | System 2.6 needs env -u GEM_HOME | `env -u GEM_HOME /usr/bin/ruby builds/log-builder_2026-10-05`
- D-20261005-04 | 2026-10-05 | [decision] | repo | Replaced Packer with a build.rb bundle | docs/specs/2026-10-05_SingleFileBuildBundle.md
- D-20261005-05 | 2026-10-05 | [find] | repo | Stock macOS Ruby 2.6.10 sets the floor | https://github.com/apple-oss-distributions/ruby/releases/tag/ruby-175
- D-20261005-06 | 2026-10-05 | [outcome] | services | Lazy day render ends per-attach re-render: 200-daily-task padded config 17.6s -> 0.69s year and 17.9s -> 0.53s month; suite 332/0, 15 outputs sha256-identical | src/models/day.rb:18
- D-20261005-07 | 2026-10-05 | [decision] | models | `Day#tasks` stays a String computed lazily from `tag_roots` plus `config_file`; `attach` invalidates with `tasks = nil`, yielding one render per printed day | src/models/day.rb:18
- D-20261005-08 | 2026-10-05 | [trap] | cli | Invalid or missing month with stdin at EOF spins the prompt loop at 100% CPU instead of exiting: `$stdin&.gets` returns nil so validity stays false | src/modules/log_builder.rb:62
- D-20261005-09 | 2026-10-05 | [decision] | repo | Renamed the default branch `master` to `main` locally and on `origin`, set the GitHub default to `main`, and retargeted 16 doc references | `gh repo view --json defaultBranchRef` -> `main`
- D-20261005-10 | 2026-10-05 | [trap] | models | `Year` hardcoded 54 weeks (378 days) and mis-seeded Monday January 1 as prior December 25, leaking an extra week into year-mode files | docs/specs/2026-10-05_YearBoundaryFullWeeks.md
- D-20261005-11 | 2026-10-05 | [outcome] | models | Fixed `Year#days` to the full Monday/Sunday weeks intersecting the year: 371 days, 378 only for a leap year starting Sunday; added edge and 1900..2100 `Date` tests | src/models/year.rb:46
- D-20261005-12 | 2026-10-05 | [outcome] | services | birth_year age rendering shipped | src/services/configured_tasks_service.rb:39
- D-20261005-13 | 2026-10-05 | [decision] | services | birth_year semantics and validation | docs/specs/2026-10-05_BirthdayAgeFromBirthYear.md
- D-20261004-01 | 2026-10-04 | [outcome] | services | tag_order_config shipped | `RUBYOPT=-r/tmp/lb_cov.rb bundle exec rspec`
- D-20261004-02 | 2026-10-04 | [decision] | services | tag_order_config semantics | docs/specs/2026-10-04_TagOrderConfig.md
- D-20261004-03 | 2026-10-04 | [decision] | services | Reserved tag-order marker raises INVALID_CONFIG | src/services/tag_merge_service.rb:19
- D-20261004-04 | 2026-10-04 | [trap] | test | tag_order tests passed without the feature | test/spec/services/add_task_service_spec.rb:1125
- D-20261004-05 | 2026-10-04 | [outcome] | services | Merge render perf trap fixed | src/services/task_printer_service.rb:44
- D-20261004-06 | 2026-10-04 | [outcome] | services | Same-day root tag merging implemented | src/services/tag_merge_service.rb:1
- D-20261004-07 | 2026-10-04 | [decision] | services | Same-day root tag merge semantics | docs/specs/2026-10-04_MergeSameDayRootTags.md

Settled and over-length entries live in `docs/discovery/archive/<id>.md`.
