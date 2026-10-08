# Config Load Validation

## Branch Context

- Target branch `config-load-validation`, cut from `main` at `7aa8276` ("Add Single-File Build Bundle (#8)").
- This spec starts from the merged single-file build. The new validator file must be added to `SOURCE_ORDER` in `build.rb:14-28`, or the Bundle will not carry it and the runtime will fail on `require`.
- This supersedes the repository TODO at `README.md:729-733` ("Validate the config at load: collect all problems, print one message, exit 1") and the `TEXT:`/`TASK:` debug-rescue item.
- The `builds/` privacy note and the deferred history rewrite are untouched.

## Context And Motivation

Today a bad config fails in three different ways, none of them good.

- A YAML syntax error raises an uncaught `Psych::SyntaxError` from `src/services/config_reader_service.rb:16`, surfacing as a raw STDERR backtrace after the user has already answered the interactive prompts.
- A misspelled `method` reaches `public_send` at `src/services/configured_tasks_service.rb:31` and raises `NoMethodError` mid-generation. A missing `month` on `to_last_day_in_month` raises `NoMethodError` from `nil - 1` at `src/services/add_task_service.rb:113`, and a missing `n_weeks` raises from `week_number % nil` at `src/services/add_task_service.rb:163`.
- Several key mistakes never raise at all. `to_specific_date` with no `month` attaches nothing (`src/services/add_task_service.rb:19`); a String template name that does not exist silently becomes a leaf named after the typo (`src/services/configured_tasks_service.rb:21-24`); a duplicate YAML key is silently collapsed, then the hash is reversed at `src/services/config_reader_service.rb:32`, so which entry survives is counter-intuitive.

The result is either a crash after prompts, or a year file that is quietly missing entries. The user runs this once a year and reads the output as a record, so a silent omission is the worst possible failure. The fix is one validation pass at load that refuses to build and reports everything wrong at once.

## Glossary

- **Config Validation**: the single load-time pass that inspects the whole parsed config and reports every problem before any output file is written. _Avoid_: lint, check, sanity pass.
- **Inline Template**: a `template` value supplied directly as a Hash or Array on a task, instead of naming an entry under `task_templates_config`. _Avoid_: anonymous template, embedded template.
- **Task Method**: a method on `AddTaskService` named by a task's `method` key, for example `to_specific_date`. _Avoid_: handler, action, verb.
- See `docs/GLOSSARY.md` for Tag, Configured Task, and Bundle.

## Current State

- Config is parsed with `YAML.load_file` at `src/services/config_reader_service.rb:16`; no duplicate detection, no schema, no type checks.
- The reader has a file-missing path only: `raise FileNotFoundError` at `src/services/config_reader_service.rb:13`, message `ConfigConstants::ERRORS[:FILE_NOT_FOUND]` = `File not found: %s` (`src/constants/config_constants.rb:52`).
- The CLI flow is `LogBuilder#build_file` (`src/modules/log_builder.rb:24-27`) calling `collect_user_input` (`:29-35`) and then `build_by_mode` (`:37-46`); `Year.new` reads the config at `:39`. Nothing validates before that.
- The existing CLI error path prints to STDOUT and exits 1: `puts AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_FILE]` then `raise SystemExit, 1` (`src/modules/log_builder.rb:20-21`), message `Invalid config file. Exiting...` (`src/constants/app_constants.rb:27`).
- `AddTaskService` exposes 16 public task methods (`src/services/add_task_service.rb:11,24,33,42,51,61,85,90,106,111,118,128,138,152,171,183`). `ConfigConstants::CONFIGURED_TASK_METHODS` (`src/constants/config_constants.rb:36-38`) holds only `to_specific_date`, and is used solely as the birth-year gate at `src/services/configured_tasks_service.rb:44`.
- LG generation requires `base`, `weekday`, and `weekend` under `lg_templates_config`: `src/services/printer_service.rb:66-74` concatenates `template_base` with the per-day key.
- Real top-level sections are exactly four: `tasks_config`, `task_templates_config`, `lg_templates_config`, `tag_order_config` (`src/services/config_reader_service.rb:20,28,32,36`).
- A task template is looked up by name and, on a nil result, falls back to the raw value (`src/services/configured_tasks_service.rb:21-24`); this same fallback path serves inline Hash/Array templates (`test/test_config.yml:168,175,183,193,201`).
- `TaskPrinterService#print_internal` has a `rescue StandardError` (`src/services/task_printer_service.rb:49-56`) that prints `TEXT:` and `TASK:` to STDOUT and renders the raw placeholder; it conflates an unknown `{{TASK.Name}}`, an Array-shaped target, and an unresolved variable.
- `test/blank_config.yml:2` carries the dead, misspelled key `templates_config`; it is a fixture loaded across the suite.
- Baseline before this feature: 346 examples, 0 failures; rubocop 30 files, 0 offenses.

## Goals

1. Validate the whole config once at load and refuse to generate when anything is wrong.
2. Collect every problem and print one readable report to STDERR, then exit non-zero.
3. Catch the silent-failure classes: duplicate keys, unknown or missing `method`, missing required keys, wrong value types, unknown top-level keys, and unresolved template names or variables.
4. Reject only configs that are actually wrong; keep every currently working config, including inline Hash/Array templates and the `{{TASK.}}` composed passthrough.

## User Stories

1. As the maintainer, I want a YAML syntax error reported cleanly, so that I do not read a `Psych` backtrace after answering prompts.
2. As the maintainer, I want a duplicate key reported with its section, so that I do not ship a year file with a silently dropped task.
3. As the maintainer, I want an unknown `method` rejected at load, so that I do not get a `NoMethodError` halfway through year generation.
4. As the maintainer, I want a task missing a key its method needs rejected at load, so that it cannot silently attach nothing.
5. As the maintainer, I want a quoted number or wrong-typed value rejected, so that a silent no-op becomes an error.
6. As the maintainer, I want an unknown top-level key rejected, so that a typo like `templates_config` is caught rather than ignored.
7. As the maintainer, I want a String template name that does not resolve rejected, so that a typo cannot become a leaf in the output.
8. As the maintainer, I want inline Hash/Array templates to keep working, so that existing configs are unaffected.
9. As the maintainer, I want a surviving `{{...}}` placeholder rejected, so that unresolved variables do not land literally in the record.
10. As the maintainer, I want a missing required section reported only when the requested generation needs it, so that a minimal DO config is not rejected for lacking LG sections.
11. As the maintainer, I want all problems in one message, so that I fix the config once instead of rerunning per error.
12. As the maintainer, I want the validator to run before any file is written, so that a broken config never leaves a partial artifact.
13. As the maintainer, I want the same validator inside the single-file Bundle, so that the shipped artifact rejects bad configs too.

## Non-Goals

- Changing any rendered output for a valid config. Output for `test/test_config.yml` and `test/tag_order_config.yml` stays byte-identical.
- Resolving `{{TASK.*}}` composed references. That is the separate documented trap (`docs/discovery/DISCOVERY.md:74`); this spec preserves its literal passthrough.
- An interactive "fix it for me" flow or a config editor.
- Schema versioning, config migration, or a JSON-schema dependency.
- Validating the LG per-day inner keys as a closed set; they are open-ended by day name.
- Range-checking beyond the bounds named in this spec.

## Prerequisites

- Ruby 2.6 or newer; `psych` and `yaml` from the standard library. No new gem.
- The current suite is green at 346 examples, 0 failures, and rubocop at 0 offenses.
- The `build.rb` `SOURCE_ORDER` list and the `HEADER_REQUIRES` guard remain the integration point for the Bundle.

## Design Principles

- Fail fast: validation runs before `Year.new` and before any output file is opened.
- One report: collect problems into a list and raise once; never raise on the first problem.
- Pure core: validation is a function of the parsed config hash plus the resolved mode, so it is unit-testable without files.
- No false positives: every check must be verified against the fixtures; a check that rejects a working config is a bug, not a feature.
- Same reader semantics: the validator parses with Psych like the runtime, so it rejects exactly what the runtime would reject and no more.

## Backend Requirements

### Entry Point And Call Order

- Add a class method `ConfigReaderService.validate!(config_file, mode:)` in `src/services/config_reader_service.rb`.
  - It parses the file, runs every check, and either returns the parsed Hash or raises `ConfigReaderService::InvalidConfigError`.
  - It is called exactly once, from `LogBuilder#build_by_mode` in `src/modules/log_builder.rb:37`, as the first statement, before `PrinterService.new` at `:38` and `Year.new` at `:39`.
  - Validation therefore runs after `collect_user_input` (so `@mode` is resolved) and before any output file is opened. Mode comes from argv or the prompt and is already normalised to `DO` or `LG` by that point.
- `ConfigReaderService#initialize` (`src/services/config_reader_service.rb:7-9`) keeps its current reading behavior for every other caller; it does not run validation, so the per-printer reads during rendering (`src/services/task_printer_service.rb:45`, `src/services/printer_service.rb:65`) are unchanged and carry no double-parse cost beyond today.
- `LogBuilder#build_file` (`src/modules/log_builder.rb:24-27`) rescues `ConfigReaderService::InvalidConfigError`, writes the report to STDERR, and raises `SystemExit, 1`. This mirrors the existing shape at `:20-21` but writes to STDERR, not STDOUT.

### Parse And Duplicate Detection

- Read the file as UTF-8. Raise the existing `FileNotFoundError` (`src/services/config_reader_service.rb:5,13`) unchanged when it does not exist; that path is already clean.
- Parse once with `Psych.parse(contents)` to get the AST, mapping syntax problems to a single `YAML syntax error: <message>` problem. This replaces the raw backtrace.
- Walk every `Psych::Nodes::Mapping` in the AST in pairs; when a scalar key appears twice in the same mapping, record `duplicate key '<key>' in <section>`, where `<section>` is the nearest top-level key or `top level`. Skip a key whose scalar value is `<<` (merge key), because merge keys are unsupported on the supported Psych and must not be treated as ordinary duplicates.
- After a clean parse, materialise the Ruby Hash with the same semantics as today (`YAML.load_file`), so values match what the runtime reads. On Psych 4 and 5 an alias raises `Psych::AliasesNotEnabled`; record that as a syntax-class problem with the README caveat wording rather than a raw backtrace.
- If parsing produced any problem, do not run the structural checks; report the parse problems alone, because downstream checks would be meaningless.

### Method Whitelist

- The valid `method` values are exactly `AddTaskService.instance_methods(false).map(&:to_s)` at load time, currently the 16 methods listed in Current State. Do not source the whitelist from `ConfigConstants::CONFIGURED_TASK_METHODS`, which holds only `to_specific_date`.
- Each `tasks_config` entry must have a `method` key whose value is a String in that set. Report `tasks_config['<task>']: unknown method '<value>'` otherwise, including the nil and non-String cases.
- Rename `ConfigConstants::CONFIGURED_TASK_METHODS` to `ConfigConstants::BIRTH_YEAR_METHODS` and update its one reader at `src/services/configured_tasks_service.rb:44` plus the reference in `test/spec/services/config_reader_service_spec.rb:61`, so it is no longer mistaken for a whitelist.

### Required And Forbidden Keys Per Method

- Required keys are per method and conditional. Encode a table keyed by method string with `required`, `required_unless`, and `forbidden` sets. `template` is required for every task.

| Method | Required | Conditional | Forbidden |
| --- | --- | --- | --- |
| `to_specific_date` | `day` | `month` unless `is_each` is truthy | |
| `to_each_day` | | | `day_name` |
| `to_each_weekday` | | | `day_name` |
| `to_each_weekend` | | | `day_name` |
| `to_each_xday` | `day_name` | | |
| `to_nth_xday_in_month` | `day_name`, `nth_day` | `month` unless `is_each` is truthy | |
| `to_nth_xday_in_each_month` | `day_name`, `nth_day` | | |
| `to_last_xday_in_month` | `day_name`, `month` | | |
| `to_last_xday_in_each_month` | `day_name` | | |
| `to_last_day_in_month` | `month` | | |
| `to_last_day_in_each_month` | | | |
| `to_nth_day_in_each_month` | `nth_day` | | |
| `to_nth_day_in_each_quarter` | `nth_day` | | |
| `to_xday_every_n_weeks` | `day_name`, `n_weeks` | | |
| `to_easter` | | | |
| `to_good_friday` | | | |

- Report each missing key as `tasks_config['<task>']: missing required key '<key>' for <method>`, and each forbidden key as `tasks_config['<task>']: key '<key>' is not allowed for <method>`.
- Do not require keys the method overwrites or ignores: `day` for `to_last_day_in_month` (`src/services/add_task_service.rb:113`), `month`/`day` for `to_nth_day_in_each_month` and `to_nth_day_in_each_quarter` (`:132-133,:145-146`), and `nth_day` for `to_last_xday_in_month`. Do not treat the per-task `tag` key as an error; it is overwritten at `src/services/configured_tasks_service.rb:29`.
- `birth_year` validation stays where it is (`src/services/configured_tasks_service.rb:44-58`); the load pass does not duplicate it.

### Value Types And Ranges

- `month`, `day`, `nth_day`: `Integer` only, strict. `is_each` is truthy for the conditional-required rule using Ruby truthiness, but if present it must be `true` or `false`.
- `n_weeks`: `Integer` and `>= 1`.
- `birth_year`: `Integer` (already enforced at render).
- `day_name`: must be an exact member of `Year::DAY_NAMES` (`src/models/year.rb:8-13`), case-sensitive, for every method in the table that requires it. Lowercase `monday` currently raises on some methods and silently no-ops on others; both become the same error.
- Range checks as errors: `month` in `1..12`, `nth_day` in `1..31`. Out-of-range is a silent no-op or a crash today.
- Integral Floats such as `1.0` are rejected deliberately; state this in the report text as a type error. This is the one intentional tightening of a value that could work on some methods.

### Unknown Top-Level Keys

- The allowed top-level keys are exactly `tasks_config`, `task_templates_config`, `lg_templates_config`, `tag_order_config`.
- Report `unknown top-level key '<key>'`. Before shipping, fix `test/blank_config.yml:2` from `templates_config` to `task_templates_config` so the check does not fail the suite on its own fixture.
- Do not treat `tag_order_config` as required.

### Missing Section Rules

- `tasks_config`: optional. Absent or empty is a legitimate blank calendar and must not error. This preserves `test/blank_config.yml` and the year_spec contract.
- `task_templates_config`: required if and only if `tasks_config` has at least one entry (any task performs the lookup at `src/services/configured_tasks_service.rb:21`). Report `task_templates_config is required when tasks_config is present`.
- `lg_templates_config`: required if and only if mode is `LG`. When required, `base`, `weekday`, and `weekend` must all be present, per `src/services/printer_service.rb:66-74`. Report the missing inner keys.
- `tag_order_config`: always optional (default `[]` at `src/services/config_reader_service.rb:36`).
- Do not descend into and constrain the open-ended LG per-day keys; `README.md:158-177` and `test/test_config.yml:18,25` show day-named keys beyond the three required ones.

### Template Resolution

- For each task entry, resolve `template` as follows.
  - String: look up `task_templates_config[value]`. If nil, report `tasks_config['<task>']: no template named '<value>'`.
  - Hash or Array: inline template, accepted unchanged.
  - Missing key: report `tasks_config['<task>']: missing required key 'template'`.
- This keeps the current inline-template fallback working (`test/test_config.yml:168,175,183,193,201`) while rejecting a typo in a name.

### Unresolved Placeholder

- Replace the conflated rescue at `src/services/task_printer_service.rb:49-56` with explicit checks that raise the same `InvalidConfigError` report.
  - A `{{TASK.Name}}` reference whose `configured_template_by_name(Name)` is nil is an error naming the reference and its containing template.
  - A `{{TASK.Name}}` reference whose target is not a Hash is an error.
  - After substitution, a surviving placeholder matching `/\{\{(?!TASK\.)/` is an error naming the placeholder. Exempt the `{{TASK.` prefix, whose literal passthrough is the documented separate trap (`docs/discovery/DISCOVERY.md:74`) asserted at `test/spec/services/tag_merge_service_spec.rb:342-351` and `test/spec/services/task_printer_service_spec.rb:429-436`.
- Remove the `puts "TEXT:"` and `puts "TASK:"` debug output.

### Error Report Format And Exit

- Add `ConfigReaderService::InvalidConfigError < StandardError`. Add a message constant, for example `AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_REPORT] = "Invalid configuration:\n%s"`, rendered with the newline-joined problem list.
- `LogBuilder#build_file` rescues it, writes the message with `warn` (STDERR), and raises `SystemExit, 1`. STDOUT stays for normal output, matching the chosen behavior.
- The report lists every collected problem, one per line, each naming the section and task where applicable. A clean config produces no output and behaves exactly as today.

### Files And Line Anchors

- `src/services/config_reader_service.rb`: add `validate!`, `InvalidConfigError`, the parser, and the checks; keep `initialize` and `read_file` behavior for other callers.
- `src/constants/config_constants.rb`: rename `CONFIGURED_TASK_METHODS` to `BIRTH_YEAR_METHODS` at `:36-38`.
- `src/services/configured_tasks_service.rb`: update the birth-year gate at `:44`; delete the nil fallback and its silent path at `:21-24` only if the inline Hash/Array path is preserved through a type check.
- `src/services/task_printer_service.rb`: replace the rescue at `:49-56` with explicit errors, remove the debug `puts` at `:54-55`.
- `src/modules/log_builder.rb`: call `ConfigReaderService.validate!` at the top of `build_by_mode` (`:37-39`) and rescue-publish-report at `build_file` (`:24-27`).
- `test/blank_config.yml:2`: fix `templates_config` to `task_templates_config`.
- `build.rb:14-28`: add the new or changed source paths to `SOURCE_ORDER` if a new file is created; if validation lives in `config_reader_service.rb`, no `SOURCE_ORDER` change is needed.

### Bundle Integration

- If validation is added inside existing files, the Bundle picks it up with no `SOURCE_ORDER` change; keep it that way where possible.
- After implementing, run `ruby build.rb` and commit the new Build Snapshot, per the build bundle contract.

## Frontend / UI Requirements

None. The only user-visible surface is the STDERR report text and the non-zero exit code.

## Production Risks And Mitigations

- False positive blocks a valid config: mitigated by the fixture-based test plan, the per-method conditional table, and the explicit inline-template and `{{TASK.` exemptions.
- Validator and runtime disagree on aliases or merge keys: mitigated by parsing with Psych and rejecting aliases consistently with the documented Psych behavior.
- Perf regression from a second parse: mitigated by parsing once per run at load; the per-printer reads are unchanged.
- A previously silent config now errors on first run: intended, and surfaced as a clear report rather than a crash or a wrong file.
- Existing tests that assert silent behavior: updated in the same change, listed in the Test Plan.

## Rollout Plan

1. Fix `test/blank_config.yml:2`.
2. Add the validator and error class; wire it into `LogBuilder`.
3. Replace the printer rescue and remove the debug output.
4. Update the affected specs and add the new cases.
5. Run `bundle exec rspec` and `bundle exec rubocop` to green.
6. Run `ruby build.rb` and commit the new Build Snapshot via `ship-changes`.
7. No migration, backfill, or deploy step.

## Test Plan

### `test/spec/services/config_reader_service_spec.rb` (primary unit seam)

- Valid `test/test_config.yml` and `test/tag_order_config.yml`: `validate!` returns a Hash and raises nothing.
- Syntax error: a StringIO or tmp file with a broken mapping yields an `InvalidConfigError` whose message names a syntax error, not a backtrace.
- Duplicate key: a tmp config with `tasks_config` duplicated reports `duplicate key`.
- Unknown method: a task with `method: to_nope` reports `unknown method`.
- Missing required key: `to_xday_every_n_weeks` without `n_weeks` reports `missing required key 'n_weeks'`.
- Conditional key: `to_specific_date` with `is_each: true` and no `month` is valid; without `is_each` it reports missing `month`.
- Forbidden key: `to_each_day` with `day_name` reports not allowed.
- Wrong type: `month: "1"` reports a type error; `n_weeks: 0` reports a range error; `day_name: monday` reports an invalid day name.
- Unknown top-level key: `templates_config:` reports unknown top-level key.
- Missing sections: a config with tasks and no `task_templates_config` reports it; a config with no tasks does not; mode `LG` with no `lg_templates_config` reports it and mode `DO` does not.
- Template resolution: a String name that does not resolve reports no template named; an inline Hash template passes.
- Multiple problems: a config with two faults reports both in one message.

### `test/spec/run_spec.rb` (e2e seam)

- A malformed config path exits non-zero, writes the report to STDERR, and writes no output file.

### Specs To Update

- `test/spec/services/configured_tasks_service_spec.rb:235-252`: the "missing named template renders a leaf" case flips to expect `InvalidConfigError`.
- `test/spec/services/task_printer_service_spec.rb:439-447`: reserve the placeholder case flips to expect an error; add an Array-target error case.
- `test/spec/services/config_reader_service_spec.rb:61`: rename the `CONFIGURED_TASK_METHODS` reference to `BIRTH_YEAR_METHODS`.
- Any `test/blank_config.yml` consumer stays green after the key fix.
- `docs/specs/2026-10-04_MergeSameDayRootTags.md:157`: annotate as superseded by this spec; do not edit history.

Expected suite result: 346 examples plus the new cases, 0 failures, 0 pending.

## Summary Of Changes

- [ ] `ConfigReaderService.validate!(config_file, mode:)` and `InvalidConfigError` added.
- [ ] Syntax, duplicate-key, method-whitelist, required-key, value-type, and unknown-top-level checks implemented.
- [ ] Missing-section rules implemented per mode and task presence.
- [ ] String-template resolution and unresolved-`{{...}}` errors implemented with the inline and `{{TASK.` exemptions.
- [ ] `TaskPrinterService` rescue replaced; debug `puts` removed.
- [ ] `LogBuilder` calls the validator before `Year.new` and publishes the report to STDERR with exit 1.
- [ ] `CONFIGURED_TASK_METHODS` renamed to `BIRTH_YEAR_METHODS`.
- [ ] `test/blank_config.yml:2` typo fixed.
- [ ] Affected specs updated and new cases added.
- [ ] `bundle exec rspec` green and `bundle exec rubocop` clean.
- [ ] New Build Snapshot generated with the validator inside the Bundle.

## Verification Steps

1. `bundle exec rspec` reports 0 failures and 0 pending.
2. `bundle exec rubocop` reports 0 offenses.
3. `ruby ./src/run.rb ./test/test_config.yml DO 2020 ALL /tmp/lb_valid` exits 0 and matches the pre-change output byte for byte.
4. A tmp config with a duplicate key run through `ruby ./src/run.rb` exits non-zero, prints the report to STDERR, and writes no file.
5. `ruby ./src/run.rb ./test/test_config.yml LG 2020 ALL /tmp/lb_lg` exits 0.
6. `ruby build.rb` produces a new snapshot; `/usr/bin/ruby -c` on it prints `Syntax OK`.

## Open Questions

None. Resolved decisions: strict Integer typing, the narrow String-only template error with the inline and `{{TASK.` exemptions, keep the unknown-top-level check with the fixture fix, error on unresolved variables, and the reader-unit plus run_spec seams. Assumptions the user may veto: `month` range `1..12` and `nth_day` range `1..31` are errors, and `n_weeks` must be `>= 1`.

## Post-Review Hardening

A product review after the first implementation found the pass could still destroy an existing output file and could itself raise raw backtraces. The following supersedes the matching decisions above.

- Output writes are atomic: each printer writes a sibling temp file and renames it over the target only on success, so a render-time failure leaves an existing file untouched and no partial artifact.
- The load pass also rejects a surviving non-`{{TASK.` placeholder and a `{{Name}}` reference that does not resolve to a mapping, so those fail before any write.
- Root and section type guards: the root must be a mapping; `tasks_config`, `task_templates_config`, and `lg_templates_config` must be Hash when present; `tag_order_config` must be an Array; each named template must be a Hash or Array; the LG `base`, `weekday`, and `weekend` values must be non-nil String or Array.
- Validation runs after the mode prompt and before the year and month prompts, so the user never answers every prompt before a report.
- The report includes the config file path and 1-based line numbers where the AST provides them, and suppresses the per-task `no template named` cascade when `task_templates_config` is missing.
- Coverage is standardized in the one load pass: `day` is range-checked `1..31`; `birth_year` must be an Integer and only with `to_specific_date`; `tag_order_config` entries are Strings with no duplicates; `template_variables` must be a list. The birth-year future-year and `{{AGE}}`-required checks stay in `ConfiguredTasksService` because they need the build year, but now raise `ConfigReaderService::InvalidConfigError` so the report is consistent.
- Values the review judged previously working (`is_each` other than `true` or `false`, and integral Floats) stay rejected per the decisions at `:141` and `:146`; that remains the one sanctioned tightening.
