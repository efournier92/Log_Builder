# Handoff: Single-File Build Bundle

Date: 2026-10-05. Repo: `/Users/e/mnt/bnk/cs/Log_Builder`.

## Current State

- Done: the spec is written and approved at sign-off: `docs/specs/2026-10-05_SingleFileBuildBundle.md`. Glossary terms Bundle, Build Snapshot, and Drift were added to `docs/GLOSSARY.md`. No implementation has started.
- In progress: nothing.
- Uncommitted: `docs/GLOSSARY.md` (modified) and `docs/specs/2026-10-05_SingleFileBuildBundle.md` (untracked). Discovery entries were appended this session.
- Branch: `perf/lazy-day-render`, tip `bafaa2c` ("Make Day Rendering Lazy ...").
- `main` is at `3189193`. `perf/lazy-day-render` is exactly one commit ahead and is not merged. The spec's current-state analysis was performed against this working tree, so its facts match `bafaa2c`.
- `builds/` does not exist on disk. `build_package` still exists. No `build.rb` yet.
- Baseline before this feature, with lazy render, is 332 examples and 0 failures (`docs/discovery/DISCOVERY.md`).

## Key Decisions And Why

- Replace the platform-specific Ruby Packer binary with `build.rb`, a Ruby script that concatenates `src/` into one file. Ruby Packer output does not run across platforms and needs an external toolchain.
- Minify with Ruby's bundled Prism parser, stripping comments, blank lines, and leading indentation while protecting string, symbol, regex, and heredoc ranges. No third-party Ruby minifier is production-safe. The script aborts if Prism is missing rather than falling back to regex.
- Artifact is `builds/log-builder_YYYY-MM-DD`, extensionless with a shebang and mode `0755`, deterministic content with no timestamp inside. Committed as dated snapshots only; the maintainer chooses when to build. `builds/` is un-ignored and excluded from rubocop.
- Runtime floor is Ruby 2.6+, using only the `yaml` and `fileutils` standard libraries. Stock macOS still ships Ruby 2.6.10; common Linux defaults are 3.0 or newer; the source uses no 3.x-only syntax.
- `FileParser` is test-only and moves from `src/services/file_parser_service.rb` to `test/support/file_parser.rb`, updating two requires, so the artifact carries no test scaffold.
- Verification is a new `test/spec/build_spec.rb`: header and require checks, determinism, `ruby -c`, drift against the newest committed snapshot, and three byte-identical equivalence cases against `src/run.rb`.
- `build_package` is deleted and `README.md` Build Packaging is rewritten, removing the Ruby Packer references.

## Next Actions

1. Resolve the base branch. The spec's Branch Context says cut `single-file-build` from `main`, but the latest logic (lazy day render) exists only on `perf/lazy-day-render` at `bafaa2c`. Either fast-forward or merge `perf/lazy-day-render` into `main` first, or cut `single-file-build` from `bafaa2c`. Do not branch from stale `main` if "latest logic" is required. Update the spec's Branch Context to record the choice.
2. Commit the spec and glossary via `ship-changes` so the tree is clean. Expected result: `docs/specs/2026-10-05_SingleFileBuildBundle.md` and `docs/GLOSSARY.md` committed; `implement-spec`'s dirty-tree guard would otherwise stop on the spec itself.
3. Create the chosen branch and run `implement-spec docs/specs/2026-10-05_SingleFileBuildBundle.md`.
4. Implement per the spec: add `build.rb`; move `src/services/file_parser_service.rb` to `test/support/file_parser.rb` and update `test/spec/services/file_parser_service_spec.rb:1` and `test/e2e/e2e_spec.rb:1`; delete `build_package`; edit `.gitignore` and `.rubocop.yml`; rewrite `README.md:94-107` and add the `### 2026-10-05` Version History bullet at `README.md:686`; add `test/spec/build_spec.rb`.
5. Run `ruby build.rb`. Expected result: `builds/log-builder_<today>` created with mode `0755`.
6. Run `bundle exec rspec` and `bundle exec rubocop`. Expected result: 0 failures and 0 offenses.
7. Commit source, docs, tests, and the first Build Snapshot via `ship-changes`.

## Verify Commands

- `git -C /Users/e/mnt/bnk/cs/Log_Builder branch --show-current` should print `perf/lazy-day-render` at the start.
- `git -C /Users/e/mnt/bnk/cs/Log_Builder log --oneline -1` should print `bafaa2c`.
- `git -C /Users/e/mnt/bnk/cs/Log_Builder status --short` should show only `docs/GLOSSARY.md` modified and the spec untracked before step 2.
- `bundle exec rspec` from the repo root should print 332 examples, 0 failures as the starting baseline.
- `bundle exec rubocop` from the repo root should print 0 offenses as the starting baseline.
- `ruby -v` should print 3.4.7, and `ruby -e "require 'prism'; puts Prism::VERSION"` should print a version.

## Open Risks And Blockers

- Branch divergence is the blocker to resolve first: the spec names `main`, the latest logic lives on `perf/lazy-day-render` (`bafaa2c`), unmerged.
- Ruby 2.6 is end-of-life and Apple-deprecated; the floor may need to rise if Apple removes the bundled interpreter.
- The build host needs Ruby 3.3 or newer for Prism; older build hosts will abort by design.
- Content determinism means two snapshots built from unchanged source are byte-identical, so git stores one blob and only filenames differ. This is intended.
- The privacy rewrite in `docs/privacy/history-cleanup.md` targets old large `builds/` blobs only; this feature re-introduces `builds/` into future history and does not touch that plan.
