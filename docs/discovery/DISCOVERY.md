# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.

## Entries

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
