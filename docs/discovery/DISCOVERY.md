# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.

## Entries

- 2026-10-08 | [decision] | repo | Tag and Release start now (`vYYYY.MM.DD` at the merge commit, asset = the snapshot, sha256 in notes); the deferred history rewrite (`docs/privacy/history-cleanup.md`) is amended to re-commit the tip snapshot and delete-and-recreate the tag and Release at the rewritten commit, so no pushed tag is force-moved and no tagged tree loses `builds/` | README.md:139

- 2026-10-08 | [trap] | services | `DEFAULT_OUTPUT_DIR = './'` joined as `"#{dir}/..."` printed `Wrote .//DO_...md`, and any user-passed trailing slash doubled too; switched to `File.join` with a `.` default and a `Wrote File > <path>` echo, and rejected an empty `output_dir` that raised a raw `Errno::ENOENT` | src/services/printer_service.rb:4,32-42,96

- 2026-10-08 | [trap] | services | `TagMergeService.printable_children` flattened an all-leaf child list to an array, so a `{{Template}}` inline reference among leaves never expanded; pre-#9 the raw placeholder was written to the log, post-#9 it raised `unresolved placeholder`; removed the flatten so `TaskPrinterService` resolves the reference | test/spec/services/tag_merge_service_spec.rb

- 2026-10-08 | [outcome] | build | `SOURCE_ORDER` in `build.rb` was a hand-maintained list with no completeness check, so a new `src/` file could ship absent from the Bundle yet pass the drift test; added a `build_spec` example asserting `src/**/*.rb` equals `SOURCE_ORDER` (sorted) and documented the rule in README Build Overview | test/spec/build_spec.rb

- 2026-10-08 | [outcome] | repo | Exec-bit trap root-caused: `core.filemode=false` hid true modes, so `git add` staged scripts as `100644`; set `core.filemode=true` locally and added `test/spec/executable_modes_spec.rb` (shebang files must be `100755`, other tracked files `100644`) plus `.github/workflows/ci.yml` to gate on any clone; `README.md` was wrongly committed `100755` and reset to `644`; `src/run.rb` has no shebang so its spurious `+x` was reset to `644` | `git ls-files -s README.md`; `bundle exec rspec test/spec/executable_modes_spec.rb`

- 2026-10-08 | [decision] | repo | Install captured in `bin/install` (POSIX `sh`, to be committed at mode `0755`): installs the newest `builds/log-builder_*` as `log-builder`, destination overridable, resolves its own path through symlinks, rejects a newest build with no shebang, prints zsh and bash `PATH` hints; README points at it | `git add bin/install && git ls-files -s bin/install`

- 2026-10-08 | [decision] | repo | Install the newest `builds/log-builder_*` as a stable `log-builder` via `bin/install`, and keep exactly ONE committed snapshot as the drift anchor; added `AppConstants::VERSION` (date-based) and `log-builder --version`; tag/Release rollout deferred until the history cleanup (`docs/privacy/history-cleanup.md`) is resolved | src/constants/app_constants.rb:2

- 2026-10-08 | [trap] | services | A null or non-String/Hash/Array `template` validated clean and attached nothing at exit 0; now rejected with a named-template message | src/services/config_reader_service.rb:390

- 2026-10-08 | [trap] | services | Duplicate detection compared only `key.value`, so YAML `1:` and `"1":` were false duplicates; identity now includes `key.plain` | src/services/config_reader_service.rb:144

- 2026-10-08 | [trap] | services | A list `base` with a per-day String passed LG validation, then `template_base + day_config` raised a raw `TypeError`; now matched by class at load | src/services/config_reader_service.rb:251

- 2026-10-08 | [outcome] | services | Critic hardening: null-template guard, quoted/plain duplicate fix, mixed LG type check, array guard, tag-source first-writer, `Wrote File > <path>` echo | src/services/printer_service.rb:96

- 2026-10-08 | [outcome] | services | Hardened validation: atomic writes, load-time placeholder checks, root/section type guards, file plus line numbers, and `day`/`birth_year`/`tag_order` in `validate!` | test/spec/run_spec.rb:83

- 2026-10-08 | [outcome] | services | Load validation shipped | docs/discovery/ARCHIVE.md

- 2026-10-08 | [trap] | build | `build_spec.rb:97` compares the fresh Bundle to the newest git-tracked `builds/log-builder_*`; any `src/` change fails it until the new snapshot is committed | test/spec/build_spec.rb:97

- 2026-10-08 | [decision] | services | Config load validation approved | docs/discovery/ARCHIVE.md

- 2026-10-08 | [decision] | services | String-missing-template fallback superseded | docs/discovery/ARCHIVE.md

- 2026-10-08 | [outcome] | build | Build critique fixes: exec bit and snapshot | docs/discovery/ARCHIVE.md

- 2026-10-08 | [trap] | build | build.rb committed without exec bit | docs/discovery/ARCHIVE.md

- 2026-10-05 | [outcome] | build | Single-file build implemented | docs/discovery/ARCHIVE.md

- 2026-10-05 | [trap] | services | Ruby 3.1 hash omission broke the 2.6 floor | docs/discovery/ARCHIVE.md

- 2026-10-05 | [trap] | build | System 2.6 needs env -u GEM_HOME | docs/discovery/ARCHIVE.md

- 2026-10-05 | [decision] | repo | Replaced Packer with a build.rb bundle | docs/discovery/ARCHIVE.md

- 2026-10-05 | [find] | repo | Stock macOS Ruby 2.6.10 sets the floor | docs/discovery/ARCHIVE.md

- 2026-10-05 | [outcome] | services | Lazy day render ends per-attach re-render: 200-daily-task padded config 17.6s -> 0.69s year and 17.9s -> 0.53s month; suite 332/0, rubocop clean, 15 outputs sha256-identical | src/models/day.rb:18

- 2026-10-05 | [decision] | models | `Day#tasks` stays a rendered String but computes lazily from `tag_roots` plus `config_file`; `attach` invalidates with `tasks = nil`, yielding one render per printed day | src/models/day.rb:18

- 2026-10-05 | [trap] | cli | Invalid or missing month with stdin at EOF spins the prompt loop at 100% CPU instead of exiting: `$stdin&.gets` returns nil so validity stays false | src/modules/log_builder.rb:62

- 2026-10-05 | [decision] | repo | Renamed the default branch `master` to `main` locally and on `origin`, set the GitHub default to `main`, and retargeted the 16 doc references | `gh repo view --json defaultBranchRef` -> `main`

- 2026-10-05 | [trap] | models | `Year` hardcoded 54 weeks (378 days) and mis-seeded Monday January 1 as prior December 25, leaking an extra week into year-mode files | docs/specs/2026-10-05_YearBoundaryFullWeeks.md

- 2026-10-05 | [outcome] | models | Fixed `Year#days` to the full Monday/Sunday weeks intersecting the year: 371 days, 378 only for a leap year starting Sunday; added edge and 1900..2100 `Date` tests | src/models/year.rb:46

- 2026-10-05 | [outcome] | services | birth_year age rendering shipped | docs/discovery/ARCHIVE.md

- 2026-10-05 | [decision] | services | birth_year semantics and validation | docs/discovery/ARCHIVE.md

- 2026-10-04 | [outcome] | services | tag_order_config shipped | docs/discovery/ARCHIVE.md

- 2026-10-04 | [decision] | services | tag_order_config semantics | docs/discovery/ARCHIVE.md

- 2026-10-04 | [decision] | services | Reserved tag-order marker raises INVALID_CONFIG | docs/discovery/ARCHIVE.md

- 2026-10-04 | [trap] | test | tag_order tests passed without the feature | docs/discovery/ARCHIVE.md

- 2026-10-04 | [outcome] | services | Merge render perf trap fixed | docs/discovery/ARCHIVE.md

- 2026-10-04 | [outcome] | services | Same-day root tag merging implemented | docs/discovery/ARCHIVE.md

- 2026-10-04 | [decision] | services | Same-day root tag merge semantics | docs/discovery/ARCHIVE.md

Settled and over-length entries live verbatim in `docs/discovery/ARCHIVE.md`.
