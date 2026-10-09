# Handoff: Single-File Build Bundle

> Superseded: `single-file-build` was merged as PR #8 (`7aa8276`, tag `v2026.10.05`) and the branch was deleted. The shipped record lives in `docs/discovery/ARCHIVE.md` (2026-10-05 and 2026-10-08); the Next Actions and Verify Commands below no longer resolve.

Date: 2026-10-05, updated 2026-10-08. Repo: `/Users/e/mnt/bnk/cs/Log_Builder`.

## Current State

- Branch `single-file-build`, tip `abb8fa5`, 5 commits ahead of `main` (`27b5d31`), 0 behind. No PR exists.
- The feature is implemented and all critique fixes are applied in the working tree, but nothing new is committed.
- Uncommitted: the exec-bit mode change on `build.rb` and `builds/log-builder_2026-10-05` is staged; the marker rebuild of the snapshot and edits to `build.rb`, `README.md`, the spec, `test/spec/build_spec.rb`, `DISCOVERY.md`, and this handoff are unstaged.
- Proof of green: the uncommitted tree was committed into a throwaway clone and passed `bundle exec rspec` with 346 examples, 0 failures, and `bundle exec rubocop` with 30 files, 0 offenses.
- In this working tree the drift example fails until the snapshot change is committed, because it compares against the `HEAD` blob.

## What Shipped On This Branch

- `build.rb`: deterministic `src/` concatenation; Prism strips comments, blank lines, and leading indent while protecting literals; each section is prefixed with a `# <src path>` marker.
- `builds/log-builder_2026-10-05`: Build Snapshot, 26,355 B, mode 0755, sha256 `1d4ef78331c05ad3bf4797119baa7375dc1e0cafb960962195d27ae426732bf5`.
- `test/spec/build_spec.rb`: 14 examples covering the header, requires, section markers, determinism, `ruby -c`, the `write` path, drift, and three byte-identical equivalence cases.
- `FileParser` moved to `test/support/file_parser.rb`; `build_package` deleted; `.gitignore`, `.rubocop.yml`, and `README.md` updated.

## Critique Results (2026-10-08)

- All findings applied.
- Blocker: `build.rb` and the snapshot were committed as mode `100644`, so a fresh clone cannot run `./build.rb` and rubocop flags `Lint/ScriptPermission`. Cause: `core.filemode=false` hides the bit. Fixed with `git update-index --chmod=+x`; a committed clone now shows `100755`.
- Backtrace mapping: each Bundle section now starts with `# <src path>`, so a stripped backtrace frame maps to its source file.
- README: added newest-snapshot guidance, a Psych 3 versus 4 and 5 alias caveat, a dated install form with a `log-builder` symlink, and the Ruby-dependency regression note in Version History.
- Spec: Summary Of Changes boxes ticked; source transformation now documents the section markers.
- Accepted, no code change: the spec was retrofitted in the implementation commit; evidence was self-authored; `builds/DO_2026_10.md` is a generated personal log kept out of git by the existing `DO_*.md` ignore.

## Next Actions

1. Commit everything via `ship-changes`: the exec-bit fix, the marker rebuild, and the README, spec, and test edits.
2. Re-run `bundle exec rspec` after the commit; the drift example goes green once the snapshot is committed.
3. Open a PR from `single-file-build` to `main` and merge.
4. After merge, delete the branch and prune.

## Verify Commands

- `git -C /Users/e/mnt/bnk/cs/Log_Builder rev-list --left-right --count main...single-file-build` should print `0	5`.
- `git ls-files -s build.rb` should print `100755` after the commit.
- `bundle exec rspec` prints 346 examples, 0 failures once the snapshot is committed.
- `bundle exec rubocop` prints 30 files, 0 offenses.
- `shasum -a 256 builds/log-builder_2026-10-05` prints `1d4ef78331c05ad3bf4797119baa7375dc1e0cafb960962195d27ae426732bf5`.

## Open Risks

- Ruby 2.6 is end of life and Apple deprecated. The floor can rise without source changes if Apple removes it.
- The build host needs Ruby 3.3 or newer for Prism. Older build hosts abort by design.
- Reintroducing `builds/` to history conflicts with the deferred privacy rewrite; that plan is untouched.
- `YAML.load_file` differs on Psych 3 versus Psych 4 and 5; documented in the README, not code-fixed.
