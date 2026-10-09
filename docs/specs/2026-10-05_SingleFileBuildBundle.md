# Single-File Build Bundle

## Branch Context

- Target branch: `single-file-build`, cut from `main` at `27b5d31` ("Make Day Rendering Lazy (#7)").
- The lazy render work merged as PR #7; `27b5d31` is tree-identical to `perf/lazy-day-render` at `bafaa2c`, the working tree this spec's facts were read from. The earlier note about `main` being dirty with runtime changes is superseded; those changes are committed in `27b5d31`.
- This spec supersedes the Ruby Packer build path. It does not touch commit history or the deferred privacy rewrite in `docs/privacy/history-cleanup.md`.

## Context And Motivation

The project currently ships via `build_package`, a three-line bash script that calls `rubyc` (the `ericbeland/ruby-packer` fork) to compile `src/run.rb` into a native executable under `builds/` (`build_package:3`, `README.md:98-107`).

That approach has three problems:

- The output is a platform-specific native binary, so a build made on macOS does not run on Linux or Windows. The stated goal is cross-compatibility.
- The binaries are large. Two tracked binaries once totaled about 150MB and were removed from tracking in `59769f1` (`docs/discovery/DISCOVERY.md:68`).
- It needs the Ruby Packer download plus its external toolchain (`squashfs`, `gcc`), summarized in the Ruby Packer dependencies the README links (`README.md:100-103`).

The replacement is a single self-contained Ruby file generated from `src/`, run through one command, executable by any machine that has a stock Ruby interpreter and nothing else. This is treated as a binary-like resource: it can be copied into a lib/bin directory on a system and run directly.

## Glossary

See `docs/GLOSSARY.md` for the shared project glossary. Terms this spec depends on:

- **Bundle**: the single generated Ruby file containing all of Log Builder's runtime logic, runnable on a bare Ruby 2.6+ install with no gems beyond the standard library.
- **Build Snapshot**: a committed, date-named copy of the Bundle at `builds/log-builder_YYYY-MM-DD`.
- **Drift**: the condition where the current `src/` produces a Bundle whose bytes differ from the newest committed Build Snapshot.

## Current State

All claims below were read from the working tree this session.

- Build entry: `build_package:1-3` is a bash script whose only command is `rubyc -o ./builds/log-builder_$(date +"%Y-%m-%d") ./src/run.rb`.
- Ignore rule: `builds/` is ignored at `.gitignore:5`.
- README build docs: `README.md:94-107` describe Ruby Packer, its download requirements, and `./build_package`. The word "Complile" is a typo at `README.md:105`.
- Source size: 14 files under `src/`, 1,193 lines, 33,370 bytes. Eleven files define exactly one class or module each; `src/services/config_reader_service.rb` defines a class plus a nested error class; `src/services/input_validation_service.rb` defines top-level methods; `src/run.rb` is the top-level entry.
- Requires: 25 `require_relative` lines plus `require 'yaml'` (`src/services/config_reader_service.rb:1`) and `require 'fileutils'` (`src/services/printer_service.rb:1`). No source file loads `date` at runtime.
- Load-time coupling: no cross-file constant, inheritance, or class-body reference exists. Runtime-only references (inside method bodies) do not constrain concatenation order.
- Concatenation hazards: none of `__FILE__`, `__dir__`, `$0`, `PROGRAM_NAME`, `DATA`, `BEGIN`, `END`, `at_exit`, `autoload`, or `caller` appear in `src/`. No class or module is reopened. `src/run.rb:4-20` is top-level executable code that must be last and that executes on load, which is acceptable for a binary-like artifact.
- `src/services/input_validation_service.rb:1-51` defines top-level methods on `Object` (`valid_config_file?`, `valid_mode?`, `valid_year_number?`, `valid_month?`, `valid_output_dir?`, `sanitize_month`). The Bundle must not wrap source in a module or class or these break; this is the intended design, not a defect.
- `YAML.load_file` is used at `src/services/config_reader_service.rb:16`. Psych behavior differs between Ruby 2.6 (Psych 3, unsafe load) and Ruby 3.4 (Psych 5, safe load). This is a pre-existing portability caveat and is out of scope.
- Default output directory is `'./'` (`src/services/printer_service.rb:4`), resolved against the process working directory. Concatenation does not change this.
- FileParser is test-only: `src/services/file_parser_service.rb:1` defines `class FileParser`, and its two public methods are called only from `test/spec/services/file_parser_service_spec.rb:1` and `test/e2e/e2e_spec.rb:20,182,219,250,284`. Nothing in the runtime path, README, or config references it.
- Test harness: `.rspec` sets `--default-path test`. `test/spec/run_spec.rb:6-8` runs `Open3.capture3('ruby', './src/run.rb', *args)`. `test/e2e/e2e_spec.rb:5-7` shells out to `ruby ./src/run.rb` and reads generated files. `test/constants/test_constants.rb:2-15` holds fixture paths and the `./_out_test` output directory.
- Current baseline: 332 examples, 0 failures, rubocop 28 files, 0 offenses (`docs/discovery/DISCOVERY.md`, "Lazy day render" outcome).
- Build host: `ruby 3.4.7` with `Prism 1.9.0` available (`.tool-versions:1` pins `ruby 3.4.7`).
- Source uses only Ruby 2.3+ and 2.4+ features after this change: safe navigation (`src/modules/log_builder.rb:62`) and `match?` (`src/services/input_validation_service.rb:34`). The prior Ruby 3.1 hash value omission at `src/services/tag_merge_service.rb:125,129` is expanded to `name: name` at `:127,131` behind a local `rubocop:disable Style/HashSyntax`; it was the only 3.x-only syntax found.
- Minification surface: 7 comment-only lines, 3 inline comments, 233 blank lines, and no heredocs, `=begin`/`=end` blocks, `__END__`, or multiline string literals.
- No `builds/` directory currently exists on disk.

## Goals

1. Provide one build command, `ruby build.rb`, that regenerates the Bundle from `src/`.
2. Make the Bundle run on any stock Ruby 2.6 or newer with no gem installation beyond the standard library (`yaml`, `fileutils`).
3. Make the Bundle a single file suitable for copying into a system lib or bin directory and running directly.
4. Minimize the Bundle's byte size without changing behavior, using Ruby's own parser rather than a third-party minifier.
5. Prove the Bundle behaves byte-identically to `src/run.rb`.
6. Keep a committed, date-named history of builds that the maintainer controls.
7. Remove the platform-specific Ruby Packer path from the repository.

## User Stories

1. As a maintainer, I want to run `ruby build.rb` and get a single file, so that I do not need a compile toolchain.
2. As a maintainer, I want the Bundle to run on a stock macOS Ruby 2.6.10, so that I can use it without installing rbenv, Homebrew, or asdf.
3. As a maintainer, I want the Bundle to run on common Linux defaults (Ubuntu, Debian, Fedora, Alpine, RHEL family), so that one artifact covers the machines I use.
4. As a maintainer, I want no runtime gems beyond the standard library, so that installation is a file copy.
5. As a maintainer, I want the Bundle to be small, so that it is cheap to store and ship.
6. As a maintainer, I want a committed Build Snapshot per build, so that I can see build history in git.
7. As a maintainer, I want to choose when a Build Snapshot is made, so that not every local run becomes history.
8. As a maintainer, I want a test that fails when `src/` drifts from the newest Build Snapshot, so that the committed artifact is never stale.
9. As a maintainer, I want a test that compares Bundle output to `src/run.rb` output byte for byte, so that minification cannot silently change behavior.
10. As a maintainer, I want FileParser out of the runtime Bundle, so that the artifact carries no test-only code.
11. As a maintainer, I want the old `build_package` and Ruby Packer instructions removed, so that there is one documented build path.
12. As a user of the tool, I want the installed Bundle to accept the same arguments as `run.rb`, so that my usage does not change.
13. As a maintainer, I want the Bundle to fail loudly if it is generated without a parser available, so that minified output is never produced by an unsafe fallback.
14. As a maintainer, I want the build to be deterministic, so that rebuilding unchanged source does not create a spurious diff.

## Non-Goals

- Aggressive minification that renames identifiers. No production-safe Ruby minifier exists, and renaming risks evaluation and reflection.
- Adding any runtime gem, including `minifyrb`, `ryac`, or `rbpacker`.
- Producing a native executable, an `.exe`, or a self-extracting archive. The artifact stays plain Ruby text with a shebang.
- Compressing the Bundle with gzip or an embedded archive.
- Adding a CI matrix or a release/publish pipeline. The Ruby 2.6 check is a documented manual verification step for now.
- Adding an output-path argument to the CLI. The output directory is fixed at `builds/`.
- Changing any runtime behavior, config schema, or output format.
- Rewriting old git history or acting on `docs/privacy/history-cleanup.md`.
- Pruning old Build Snapshots automatically.

## Prerequisites

- Ruby 3.3 or newer on the build host so `require 'prism'` succeeds. The pinned dev toolchain is 3.4.7 and already satisfies this.
- A clean working tree for the files this feature touches; the spec, glossary, and discovery edits are committed on the feature branch before implementation starts.
- No new entries in `Gemfile`. Prism is a Ruby 3.4 default gem; the build script does not use Bundler.
- Stock macOS `ruby 2.6.10` covers the optional Ruby 2.6 verification step directly; Docker or rbenv is the fallback on hosts without it.

## Design Principles

- Single source of truth: `src/` is authoritative; the Bundle is always generated, never hand-edited.
- Deterministic output: the Bundle contains no timestamp, hostname, path, or absolute path, so identical source yields identical bytes.
- Standard library only at runtime: `yaml` and `fileutils` are the only requires.
- No new dependencies: use Ruby's bundled Prism parser for comment and whitespace stripping.
- Smallest safe artifact: strip only constructs that cannot carry meaning (comments, blank lines, leading indentation outside literals).
- Prove equivalence: behavior is checked against `src/run.rb` byte for byte, not assumed.
- Test scaffolding belongs in `test/`: FileParser moves out of `src/`.

## Backend Requirements

This feature has no database, schema, migration, or API surface. The "backend" is the build script and the artifacts it produces.

### Build Script Contract

Create `build.rb` at the repository root.

- Shebang line: `#!/usr/bin/env ruby`.
- Magic comment on line 2: `# frozen_string_literal: true`. Any string buffer `build.rb` mutates must be created unfrozen (`+''`), or the pragma raises `FrozenError`.
- File mode: `0755`, so `./build.rb` also works.
- Requires at the top: `require 'prism'`, `require 'date'`, `require 'fileutils'`.
- Define `module LogBuilderBundler`.
- CLI entry guarded by `if __FILE__ == $PROGRAM_NAME`, which calls `LogBuilderBundler.write(File.expand_path(__dir__), date: Date.today)`.

`LogBuilderBundler` constants:

- `SOURCE_ORDER`: the ordered list below, relative to the repository root. Order is fixed for determinism even though no load-time dependency forces it; `src/run.rb` must be last.
  1. `src/constants/app_constants.rb`
  2. `src/constants/config_constants.rb`
  3. `src/models/day.rb`
  4. `src/models/year.rb`
  5. `src/services/config_reader_service.rb`
  6. `src/services/task_printer_service.rb`
  7. `src/services/tag_merge_service.rb`
  8. `src/services/add_task_service.rb`
  9. `src/services/printer_service.rb`
  10. `src/services/configured_tasks_service.rb`
  11. `src/services/input_validation_service.rb`
  12. `src/modules/log_builder.rb`
  13. `src/run.rb`
- `BUILD_DIR = 'builds'`.
- `FILE_PREFIX = 'log-builder_'`.
- `DATE_FORMAT = '%Y-%m-%d'`.
- `HEADER`: the exact header described below.
- `HEADER_REQUIRES = %w[yaml fileutils]`: the exact non-relative requires `HEADER` carries; the build raises when the recorded source requires differ.

`LogBuilderBundler.build(root)` returns the Bundle as a `String` and writes nothing.

`LogBuilderBundler.write(root, date:)` calls `build(root)`, creates `builds/` when missing, computes the path `File.join(root, BUILD_DIR, "#{FILE_PREFIX}#{date.strftime(DATE_FORMAT)}")`, writes the bytes, sets mode `0755`, and returns the path. It overwrites an existing same-day snapshot.

If `require 'prism'` raises `LoadError`, the script must abort non-zero with a message naming the missing parser and the Ruby 3.3+ requirement. There is no regex fallback; failing loudly is required so the Bundle is never produced by an unsafe strip.

### Bundle Header

The first lines of the generated Bundle are byte-exact:

```ruby
#!/usr/bin/env ruby
# Generated by build.rb from src/. Do not edit by hand.
# Run `ruby build.rb` to regenerate.
require 'yaml'
require 'fileutils'
```

The header carries no date, so the Bundle content is deterministic. It deliberately omits a `frozen_string_literal` magic comment: `src/services/task_printer_service.rb:9,20` mutates `@output = ''` with `<<`, so frozen literals would raise `FrozenError` and break the equivalence requirement. The two `require` lines are extracted from the sources and hoisted here in first-seen order, so `yaml` precedes `fileutils`. No `require_relative` or other project `require` may remain anywhere in the Bundle.

### Source Transformation

Apply this to each file in `SOURCE_ORDER`, then concatenate in order with a single blank line between files, prefixing each file's stripped body with a marker comment `# <relative path>` (for example `# src/models/day.rb`) so a Bundle backtrace frame maps back to its source file.

1. Read the file as UTF-8.
2. Remove every line whose stripped text matches `/\Arequire_relative\b/`.
3. Remove every line whose stripped text matches `/\Arequire\s+['"][^'"]+['"]/`, and record the non-relative require. A require is non-relative when the quoted name does not start with `.` or `/`. The build raises when the recorded list differs from `HEADER_REQUIRES`, so a future stdlib require is never silently dropped.
4. Parse the remaining text once with `Prism.parse` and collect two offset sets:
   - comment ranges from `result.comments`.
   - protected literal ranges from every string, symbol, regular expression, and heredoc node. In Prism these are `StringNode`, `InterpolatedStringNode`, `XStringNode`, `InterpolatedXStringNode`, `SymbolNode`, `InterpolatedSymbolNode`, `RegularExpressionNode`, `InterpolatedRegularExpressionNode`, `MatchLastLineNode`, and any heredoc node, whose location already spans its body.
5. Walk the lines of the remaining text:
   - If the line's start offset falls inside a protected literal range, emit the line unchanged.
   - Otherwise, remove any comment range intersecting the line, strip leading spaces and tabs, and drop the line entirely if nothing but whitespace remains.
6. Join the surviving lines with `\n`.

This removes comments, blank lines, and leading indentation while preserving literal content exactly. `=begin`/`=end` blocks do not occur in `src/`; if one appears later, its whole span is removed. Trailing whitespace outside literals may be removed but is not required.

The current source has no heredocs or multiline string literals, so the protected-range logic is a correctness guard rather than an active path. It must still be implemented, because a future literal must not be corrupted.

### FileParser Move

- Move `src/services/file_parser_service.rb` to `test/support/file_parser.rb`, creating `test/support/`.
- Keep the class name `FileParser` and both public methods unchanged.
- Update the require in `test/spec/services/file_parser_service_spec.rb:1` from `./src/services/file_parser_service` to `./test/support/file_parser`.
- Update the require in `test/e2e/e2e_spec.rb:1` from `./src/services/file_parser_service` to `./test/support/file_parser`.
- Do not change any example body in either spec. This keeps all five e2e date-indexed assertion blocks and the FileParser unit examples working.
- After the move, `src/` has 13 files, exactly the 13 listed in `SOURCE_ORDER` (including `src/run.rb`); the moved file is not in the list.

### Artifact Tracking

- Remove the `builds/` line from `.gitignore:5` so Build Snapshots are tracked.
- Add to `.rubocop.yml` under `AllCops` an exclusion for the generated artifact, because the extensionless file has a Ruby shebang and would otherwise be inspected:

```yaml
AllCops:
  NewCops: disable
  Exclude:
    - 'builds/**/*'
```

- No automatic pruning of old snapshots. The maintainer decides when to build and when to keep a snapshot.
- Because the Bundle content is deterministic, two snapshots built from unchanged source are byte-identical; git stores the blob once and only the filename differs.
- This re-introduces `builds/` into future history. The deferred privacy rewrite in `docs/privacy/history-cleanup.md` targets the old large binary blobs only and is unaffected.

### Documentation And Cleanup

- Delete `build_package`.
- Rewrite `README.md:94-107` (Build Packaging):
  - Remove the Ruby Packer fork link and the download-requirements list.
  - State that `ruby build.rb` produces `builds/log-builder_YYYY-MM-DD`, a single self-contained Ruby file.
  - State the runtime requirement: any stock Ruby 2.6 or newer, with only the `yaml` and `fileutils` standard libraries. State that rebuilding from source needs Ruby 3.3 or newer for `prism`.
  - Give the run and install forms: run `ruby builds/log-builder_YYYY-MM-DD YOUR_CONFIG.yml` (the repo sample is `test/test_config.yml`); install the newest dated file as a stable `log-builder` by running `./bin/install` (destination override as its argument, defaulting to `$HOME/.local/bin`), into a directory on `PATH`, noting the `PATH` export for the destination and `sudo` only for system directories such as `/usr/local/bin`.
  - Note that the generated file is not edited by hand and is regenerated with `ruby build.rb`.
- Add a `Version History` entry under the existing `### 2026-10-05` heading describing the single-file build and the retirement of the Ruby Packer binary path.

## Frontend / UI Requirements

None. This feature has no user interface, and no backend enum values map to labels.

## Production Risks And Mitigations

- Minification changes semantics: mitigated by protecting literal ranges during the strip, by the `ruby -c` syntax check, and by byte-identical behavior tests against `src/run.rb`.
- Committed snapshot drifts from source: mitigated by the drift example in `build_spec.rb`, which fails when `src/` produces different bytes than the newest snapshot.
- Generated code bloats repository history: mitigated because content is deterministic and git deduplicates identical blobs; the maintainer controls build frequency.
- Reintroducing `builds/` to future history conflicts with the privacy plan: documented here; the plan only removes old binary blobs and is untouched.
- Ruby 2.6 is end-of-life and Apple-deprecated: accepted to reach stock macOS; the source uses no newer features after the `tag_merge_service.rb` normalization; verified on stock `ruby 2.6.10` (syntax check plus a full DO-year run, byte-identical output). If Apple removes Ruby, the floor can rise without source changes.
- `YAML.load_file` parses differently on Psych 3 versus Psych 5: pre-existing, out of scope, and flagged so it is not mistaken for a build regression.
- Prism is unavailable on the build host: `build.rb` aborts non-zero rather than emitting unminified or regex-stripped output, keeping the artifact trustworthy.
- Concurrent builds overwrite the same-day snapshot: acceptable for a single-maintainer tool; content is deterministic so the result is the same.
- The top-level code in `src/run.rb` executes if the Bundle is required rather than run: intentional for a binary-like artifact; the artifact is not intended to be required.

## Rollout Plan

1. Sync `main` to `origin/main` at `27b5d31`, branch `single-file-build` from `main`, and commit the spec docs.
2. Normalize `src/services/tag_merge_service.rb:127,131` to explicit hash values for the Ruby 2.6 floor, move FileParser to `test/support/`, and update the two test requires.
3. Add `build.rb` with the module and CLI.
4. Delete `build_package`; update `.gitignore`, `.rubocop.yml`, and `README.md`.
5. Run `ruby build.rb` to create `builds/log-builder_<today>` from the current source.
6. Add `test/spec/build_spec.rb`.
7. Run `bundle exec rspec` and `bundle exec rubocop` to green.
8. Commit the source, docs, tests, and the first Build Snapshot via `ship-changes`. No migration, backfill, or deploy step exists.

## Test Plan

### `test/spec/build_spec.rb` (new)

Requires `./build`, `open3`, `tmpdir`, `fileutils`, `date`. Define `ROOT = File.expand_path('../..', __dir__)` and `subject(:bundle) { LogBuilderBundler.build(ROOT) }`.

- Happy path, header: first line is exactly `#!/usr/bin/env ruby`.
- Happy path, header: second line is exactly `# Generated by build.rb from src/. Do not edit by hand.`.
- Happy path, type: `LogBuilderBundler.build(ROOT)` returns a `String`.
- Happy path, requires: the Bundle contains exactly one occurrence of `require 'yaml'` and exactly one of `require 'fileutils'`, each appearing before the first line beginning with `module` or `class`.
- Happy path, no project requires: the Bundle matches neither `/require_relative/` nor `/require\s+['"]\.\//`.
- Happy path, section markers: for every path in `SOURCE_ORDER`, the Bundle contains a line exactly equal to `# <path>`, so a backtrace frame maps to its source file.
- Determinism: two calls to `LogBuilderBundler.build(ROOT)` return equal strings, proving no timestamp leaks into content.
- Syntax: write the Bundle to a `Dir.mktmpdir` file; `Open3.capture3('ruby', '-c', path)` exits `0` and prints `Syntax OK`.
- `write` path: `Dir.mktmpdir` with `FileUtils.cp_r` of `src/`; `LogBuilderBundler.write(tmp, date: Date.new(2026, 1, 1))` returns `<tmp>/builds/log-builder_2026-01-01`, writes bytes equal to `bundle`, sets mode `0755`, and a second call with the same date overwrites the file.
- Drift: list snapshots tracked at `HEAD` via `git ls-files -- builds/` filtered to `log-builder_*`; when any are tracked, take the newest by filename and assert `bundle` equals the `git show HEAD:<newest>` bytes. When none are tracked (the first snapshot is not committed yet), fall back to the filesystem glob `File.join(ROOT, 'builds', 'log-builder_*')`. When nothing is found, fail the example with a clear message; a missing snapshot is a failure, never a skip. This is the only example that reads committed artifacts and it never writes them.
- Equivalence, DO year: write the Bundle to a tmp file; run `ruby ./src/run.rb ./test/test_config.yml DO 2020 ALL <src_out>` and `ruby <bundle> ./test/test_config.yml DO 2020 ALL <bundle_out>` from `ROOT`; expect both exit statuses `0` and `File.binread(bundle_out/DO_2020.md) == File.binread(src_out/DO_2020.md)`.
- Equivalence, LG year: the same comparison with mode `LG`, comparing `LG_2020.md`.
- Equivalence, tag order and merge: the same comparison with mode `DO`, year `2020`, month `ALL`, config `./test/tag_order_config.yml`, comparing `DO_2020.md`.
- Error condition: running the Bundle with a missing config path exits non-zero and prints `AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_FILE]`, matching the existing `test/spec/run_spec.rb:50-65` behavior.

Do not invoke the CLI `ruby build.rb` from the suite, because it writes to the fixed `builds/` directory and would dirty the tree; the `write` test above uses a tmp root instead. The CLI guard is covered by the manual verification step below.

### `test/spec/services/file_parser_service_spec.rb` (modified)

- Only the require on line 1 changes to `./test/support/file_parser`. All nine examples stay identical.

### `test/e2e/e2e_spec.rb` (modified)

- Only the require on line 1 changes to `./test/support/file_parser`. All contexts and assertions stay identical.

Expected suite result after the change: the current 332 examples plus the new build examples, 0 failures, 0 pending.

## Summary Of Changes

- [x] `build.rb` added at the repository root with `LogBuilderBundler.build`, `LogBuilderBundler.write`, the `SOURCE_ORDER`, the deterministic header, and the Prism-based strip.
- [x] `build.rb` records source requires and raises when they differ from `HEADER_REQUIRES`.
- [x] `build_package` deleted.
- [x] `src/services/file_parser_service.rb` moved to `test/support/file_parser.rb`.
- [x] `src/services/tag_merge_service.rb:127,131` hash value omission expanded to `name: name` so the Bundle parses on Ruby 2.6.
- [x] `test/spec/services/file_parser_service_spec.rb:1` require updated.
- [x] `test/e2e/e2e_spec.rb:1` require updated.
- [x] `test/spec/build_spec.rb` added with the header, requires, determinism, syntax, the `write` path, drift, and three equivalence cases.
- [x] `.gitignore` no longer ignores `builds/`.
- [x] `.rubocop.yml` excludes `builds/**/*`.
- [x] `README.md` Build Packaging rewritten and the Ruby Packer references removed.
- [x] `README.md` Version History entry added under `### 2026-10-05`.
- [x] `builds/log-builder_<date>` Build Snapshot generated and committed.
- [x] `bundle exec rspec` green.
- [x] `bundle exec rubocop` clean.

## Verification Steps

1. `ruby build.rb` prints or returns `builds/log-builder_<today>` and the file exists with mode `0755`.
2. `ruby -c builds/log-builder_<today>` prints `Syntax OK`.
3. `rg -n 'require_relative|require ["'"'"']\./' builds/log-builder_<today>` returns nothing.
4. `wc -c src/**/*.rb` sum versus `wc -c builds/log-builder_<today>` shows the Bundle is smaller than the raw source sum (31,168 bytes plus header), proving the strip ran.
5. `ruby builds/log-builder_<today> ./test/test_config.yml DO 2020 ALL /tmp/lb_bundle` and `ruby ./src/run.rb ./test/test_config.yml DO 2020 ALL /tmp/lb_src`, then `diff -r /tmp/lb_src /tmp/lb_bundle` reports no differences.
6. `ruby builds/log-builder_<today> ./test/test_config.yml LG 2020 ALL /tmp/lb_bundle_lg` and the matching `src/run.rb` run diff clean.
7. `bundle exec rspec` reports 0 failures and 0 pending.
8. `bundle exec rubocop` reports 0 offenses and does not inspect `builds/`.
9. Ruby 2.6 compatibility: on stock macOS, `/usr/bin/ruby -c builds/log-builder_<today>` prints `Syntax OK` and `env -u GEM_HOME /usr/bin/ruby builds/log-builder_<today> ./test/test_config.yml DO 2020 1 /tmp/lb26` exits `0` (the `env -u` strips a Homebrew `GEM_HOME` that shadows system psych/date on this machine). On hosts without system Ruby 2.6, the equivalent Docker `ruby:2.6` commands apply.
10. `git status` shows the snapshot tracked and no generated scratch files.

## Open Questions

None. All frontier decisions are resolved.
