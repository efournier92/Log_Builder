# Each Weekday Scheduling

Branch context: no feature branch was created. This spec targets the repository default branch (`master`) of the `Log_Builder` Ruby CLI. It adds two scheduling methods to the existing `to_*` suite: `to_each_weekday` and `to_each_weekend`.

## Context And Motivation

The tool attaches a configured task to days chosen by a scheduling method named in each `tasks_config` entry (`src/services/configured_tasks_service.rb:19`, `src/services/configured_tasks_service.rb:28`). The suite has a general attach-to-all method, `to_each_day` (`src/services/add_task_service.rb:20`), and a single-day method, `to_each_xday` (`src/services/add_task_service.rb:30`). There is no way to target the Monday-to-Friday set or the Saturday-to-Sunday set as a group, so recurring workday routines and recurring weekend routines each need five or two separate config entries with `to_each_xday`.

The `Year` model already names both sets: `WEEKDAY_DAY_NAMES = %w[Monday Tuesday Wednesday Thursday Friday]` at `src/models/year.rb:9` and `WEEKEND_DAY_NAMES = %w[Saturday Sunday]` at `src/models/year.rb:8`. This feature exposes those existing sets as scheduling methods.

## Glossary

No `docs/GLOSSARY.md` change is required. The load-bearing terms are restated here so the spec stands alone.

- **Configured task**: an entry under `tasks_config` that a scheduling method attaches to one or more days.
- **Day**: one element of `do_year.days`, a `Day` with a `name` (`Monday` through `Sunday`), `month`, `month_day`, and `year` (`src/models/day.rb:3`).
- **Weekday**: a day whose `name` is in `Year::WEEKDAY_DAY_NAMES`, meaning Monday, Tuesday, Wednesday, Thursday, or Friday.
- **Weekend day**: a day whose `name` is in `Year::WEEKEND_DAY_NAMES`, meaning Saturday or Sunday.
- **Attach**: the private `AddTaskService#attach` step that resolves the task's tag roots and renders the day (`src/services/add_task_service.rb:179`).

## Current State

- `AddTaskService#to_each_day` iterates `do_year.days` and attaches to every day (`src/services/add_task_service.rb:24`). It reads and validates `day_name` even though the value is unused (`src/services/add_task_service.rb:21`).
- `AddTaskService#to_each_xday` iterates `do_year.days` and attaches only when `day.name == day_name` (`src/services/add_task_service.rb:34` and `:35`). It raises `ConfigConstants::ERRORS[:INVALID_DAY_NAME]` for an unknown name (`src/services/add_task_service.rb:32`).
- Every scheduling method ends by returning `do_year` (`src/services/add_task_service.rb:27`, `:37`).
- `ConfiguredTasksService#add_configured_tasks` resolves the method name from config and calls `add_task_service.public_send(method, year, config)` (`src/services/configured_tasks_service.rb:28`). There is no method registry and no allow-list; a new public method on `AddTaskService` is reachable immediately. `ConfigConstants::CONFIGURED_TASK_METHODS` holds only `SPECIFIC_DATE` (`src/constants/config_constants.rb:31`) and is not consulted at dispatch.
- The `odd_only` and `even_only` month filters are applied only by `to_specific_date` (`src/services/add_task_service.rb:13`) and `to_nth_xday_in_month` (`src/services/add_task_service.rb:56`) through `skip_month` (`src/services/add_task_service.rb:193`). `to_each_day` and `to_each_xday` do not apply them.
- The `to_*` methods are documented in the README supported-methods list (`README.md:232`) and per-method examples (`README.md:261`), with `to_each_xday` at `README.md:275`.
- Soft convention: scheduling methods resolve their tag through `attach`, which delegates to `TagMergeService` (`src/services/add_task_service.rb:180`). New methods must reuse `attach` so same-day tag merging and rendering stay consistent.
- No caching, state machine, or audit subsystem is involved. The CLI builds one year in a single process.

## Goals

- Add `AddTaskService#to_each_weekday` that attaches a configured task to every Monday-through-Friday day in `do_year.days`.
- Add `AddTaskService#to_each_weekend` that attaches a configured task to every Saturday and Sunday day in `do_year.days`.
- Reuse the existing `Year::WEEKDAY_DAY_NAMES` and `Year::WEEKEND_DAY_NAMES` constants rather than re-listing day names.
- Ignore the `odd_only` and `even_only` filters, matching `to_each_day` and `to_each_xday`.
- Raise `ConfigConstants::ERRORS[:INVALID_DAY_NAME]` when a config contains a `day_name` key, regardless of its value, so a stray day selector on a fixed-set method fails fast.
- Reuse the existing `attach` path so rendering, tag merging, and return values match the rest of the suite.
- Document both methods in the README, including a Version History entry.
- Complete the README supported-methods list with the pre-existing `to_each_day` entry and example, so the list covers all sixteen public scheduling methods.
- Cover the behavior end to end through `run.rb` with a dedicated fixture.

## User Stories

1. As the log author, I want a `to_each_weekday` method, so that a workday routine appears on every Monday through Friday without five separate `to_each_xday` entries.
2. As the log author, I want a `to_each_weekend` method, so that a weekend routine appears on every Saturday and Sunday without two separate entries.
3. As the log author, I want the weekday method to leave Saturday and Sunday untouched, so that workday-only content does not leak into weekends.
4. As the log author, I want the weekend method to leave Monday through Friday untouched, so that weekend-only content does not leak into workdays.
5. As the log author, I want both methods to ignore `odd_only` and `even_only`, so that they behave like the other `to_each_*` methods I already use.
6. As the log author, I want to schedule by method name only, with no extra config keys, so that a weekday or weekend task needs only `method` and `template`.
7. As the log author, I want a weekday task and a weekend task that render the same root tag to merge on the shared day, so that existing same-day merging still applies.
8. As the log author, I want a weekday task that also matches another task on the same day to merge normally, so that the new methods do not bypass merging.
9. As the maintainer, I want the new methods to reuse `attach` and the existing day-name constants, so that the diff is small and no day names are duplicated.
10. As the maintainer, I want both methods covered at the `AddTaskService` unit seam, so that behavior is pinned without touching end-to-end fixtures.
11. As the maintainer, I want the README supported-methods list and examples updated, so that the new methods are discoverable.
12. As the maintainer, I want the new methods to return `do_year`, so that they match the return contract of every other scheduling method.
13. As the maintainer, I want a stray `day_name` on either new method to raise the existing invalid-day-name error, so that a copy-pasted configuration fails loudly instead of silently ignoring the key.
14. As the maintainer, I want a real `run.rb` end-to-end case over a dedicated fixture, so that config-to-output behavior is proven without disturbing existing characterization assertions.
15. As the maintainer, I want a README Version History entry, so that the new methods are recorded as a released capability.

## Non-Goals

- A configurable list of day names. The sets are fixed to the existing `Weekday` and `Weekend` definitions.
- Excluding holidays. No holiday calendar exists in the codebase.
- Honoring `odd_only` or `even_only` in either new method.
- Changing `to_each_day`, `to_each_xday`, or any other existing method.
- A method registry or allow-list. Dispatch stays `public_send` by config method name.
- Any change to `ConfiguredTasksService`, `TagMergeService`, `Day`, `Year`, `PrinterService`, or the config schema.
- Editing `test/test_config.yml` or the existing byte-identical e2e assertion at `test/e2e/e2e_spec.rb:135`. End-to-end coverage uses a new dedicated fixture and a new e2e context instead.
- Accepting or acting on `day_name`. The key is rejected when present, never used to select days.
- A `docs/GLOSSARY.md` change; weekday and weekend are general terms here.

## Prerequisites

- Ruby 3.4.7 as pinned in `.tool-versions`.
- `bundle install` already run for the repository.
- No schema, database, external service, migration, or backfill is involved. This is a single-process CLI.

## Design Principles

- Mirror the existing `to_each_xday` shape: iterate `do_year.days`, guard with a name predicate, call `attach`, return `do_year`.
- Reuse `Year::WEEKDAY_DAY_NAMES` and `Year::WEEKEND_DAY_NAMES` as the single source of truth for the sets. `AddTaskService` already requires `../models/year` (`src/services/add_task_service.rb:1`), so the constants are in scope.
- Reject a `day_name` key when it is present, regardless of its value, with the existing `INVALID_DAY_NAME` error, so a fixed-set method cannot silently ignore a day selector.
- Do not call `skip_month`; the `to_each_*` family ignores month filters.
- Keep the source diff to two public methods. Tests, README, and one new e2e fixture are added, but no other `src/` file changes and no new `src/` file is created.

## Backend Requirements

### New Method `AddTaskService#to_each_weekday`

Insert immediately after `to_each_day` ends at `src/services/add_task_service.rb:28`, before `to_each_xday` at `:30`.

```ruby
def to_each_weekday(do_year, config)
  if config.key?(ConfigConstants::KEYS[:DAY_NAME])
    raise format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
  end

  do_year.days.each do |day|
    attach(day, config, do_year) if Year::WEEKDAY_DAY_NAMES.include?(day.name)
  end
  do_year
end
```

Behavior:

- Attaches to every day in `do_year.days` whose `name` is `Monday`, `Tuesday`, `Wednesday`, `Thursday`, or `Friday`.
- Does not attach to any Saturday or Sunday.
- Raises `ConfigConstants::ERRORS[:INVALID_DAY_NAME]` when the config hash contains the `day_name` key, regardless of its value (including `nil` or `false`). The message is formatted with that value.
- Reads `day_name` only to reject it; the tag is read through `attach` (`ConfigConstants::KEYS[:TAG]`).
- Applies no `odd_only` or `even_only` filter.
- Matches by `day.name` only, so it applies to the days built in `do_year.days` including any adjacent-year spillover days, exactly as `to_each_xday` does.
- Returns `do_year`.

### New Method `AddTaskService#to_each_weekend`

Insert immediately after `to_each_weekday`.

```ruby
def to_each_weekend(do_year, config)
  if config.key?(ConfigConstants::KEYS[:DAY_NAME])
    raise format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
  end

  do_year.days.each do |day|
    attach(day, config, do_year) if Year::WEEKEND_DAY_NAMES.include?(day.name)
  end
  do_year
end
```

Behavior:

- Attaches to every day in `do_year.days` whose `name` is `Saturday` or `Sunday`.
- Does not attach to any Monday through Friday.
- Raises `ConfigConstants::ERRORS[:INVALID_DAY_NAME]` when the config hash contains the `day_name` key, regardless of its value.
- Reads `day_name` only to reject it; the tag is read through `attach`.
- Applies no `odd_only` or `even_only` filter.
- Returns `do_year`.

### Error Message Note

`ConfigConstants::ERRORS[:INVALID_DAY_NAME]` renders as `Invalid day name: %s` (`src/constants/config_constants.rb:45`). Reusing it means a supplied but real name such as `Monday` produces `Invalid day name: Monday`. This is accepted: the value is rejected because these methods take no day selector, even when it names a real day, and no new error constant is added. Tests assert the reused format exactly.

### Unchanged Surfaces

- `ConfigConstants::KEYS` is not extended; neither method introduces a config key.
- `ConfigConstants::CONFIGURED_TASK_METHODS` (`src/constants/config_constants.rb:31`) is not extended; it is not part of dispatch.
- `ConfiguredTasksService#add_configured_tasks` needs no change. Its `public_send(method, year, config)` at `src/services/configured_tasks_service.rb:28` reaches both new methods by their config names `to_each_weekday` and `to_each_weekend`.
- `TagMergeService` and `AddTaskService#attach` need no change; both methods call `attach`, so same-day merging applies unchanged.
- No schema, API surface, creation-time capture, caller refactor, backfill, audit trail, or locking is involved.
- `TestConstants::CONFIG_FILES`, `test/e2e/e2e_spec.rb`, and the README are additive-only changes; existing entries and assertions are untouched.

## Frontend And UI Requirements

Not applicable. The deliverable is a CLI and generated Markdown files, and both methods are silent by construction. Generated tag indentation and separators come from the existing `attach` and `TagMergeService` render path and must not change.

## Production Risks And Mitigations

- Divergence between the two new methods. Mitigation: both share the identical shape, differ only in the constant, and are covered by mirrored unit cases below.
- Duplicated or drifting day-name lists. Mitigation: reuse `Year::WEEKDAY_DAY_NAMES` and `Year::WEEKEND_DAY_NAMES`; do not re-list names.
- Accidentally applying month filters. Mitigation: no `skip_month` call, plus an explicit ignore-filters test per method.
- Accidentally bypassing tag merging. Mitigation: both methods call `attach`; add a merge-on-shared-day test if a regression is observed, though existing merge coverage already exercises `attach`.
- Return-value drift. Mitigation: assert each method returns `do_year`.
- Performance. Negligible; two linear scans over the same `do_year.days` array the existing methods already scan.

## Rollout Plan

Test-first is mandatory for every step: write the failing test, run it and capture the red result, then implement until it passes. Do not write implementation before its failing test exists.

1. Add the `#to_each_weekday` cases to `test/spec/services/add_task_service_spec.rb`, run them red.
2. Implement `AddTaskService#to_each_weekday`, run the cases green.
3. Add the `#to_each_weekend` cases, run them red.
4. Implement `AddTaskService#to_each_weekend`, run the cases green.
5. Add `test/each_weekday_config.yml`, `TestConstants::CONFIG_FILES[:WEEKDAY_PATH]`, and the new e2e context. This context is characterization coverage added after both methods already exist, so it is expected to pass on the first run; the test-first red capture applies to the unit steps above, not here.
6. Update the README supported-methods list, examples, and Version History entry.
7. Run the full suite and rubocop. Single commit on `master`. No flag, no migration, no deploy step.

## Test Plan

Testing happens at two seams: the existing `AddTaskService` unit seam and one new end-to-end seam through `run.rb`. Use the existing unit setup (`AddTaskService.new` at `test/spec/services/add_task_service_spec.rb:16` and `Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH])` at `:18`) and the existing `get_day_from_year(do_year, year, month, month_day)` helper at `:8`. `2020-01-01` is a Wednesday; `2020-01-02` is Thursday; `2020-01-04` is Saturday; `2020-01-05` is Sunday; `2020-01-06` is Monday; `2020-01-10` is Friday; `2019-12-30` is a spillover Monday in `do_year.days` (the existing spillover test at `:755`); `2020-02-01` is a Saturday; `2020-02-03` is a Monday.

### `describe '#to_each_weekday'`

- Attaches the tag to a Monday, Wednesday, and Friday: `2020-01-06`, `2020-01-01` (Wednesday), and `2020-01-10` each `include(tag)`.
- Does not attach the tag to `2020-01-04` (Saturday) or `2020-01-05` (Sunday).
- Ignores `even_only`: with `ConfigConstants::KEYS[:EVEN_ONLY?] => true`, `2020-01-06` (January, odd month, Monday) still `include(tag)`.
- Ignores `odd_only`: with `ConfigConstants::KEYS[:ODD_ONLY?] => true`, a February Monday (for example `2020-02-03`) still `include(tag)`.
- Returns `do_year`: `expect(@service.to_each_weekday(@do_year, config)).to eq(@do_year)`.
- Does not raise when `day_name` is absent.
- Raises for a supplied but valid `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => 'Monday'`, `expect { @service.to_each_weekday(@do_year, config) }.to raise_error(format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], 'Monday'))`.
- Raises for an invalid `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay'`, the same `INVALID_DAY_NAME` error.
- Raises for a present but nil `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => nil`, the `INVALID_DAY_NAME` error, proving detection is by key presence, not truthiness.
- Covers a spillover day: `get_day_from_year(do_year, 2019, 12, 30)` (the spillover Monday at `:755`) includes the tag, so the name-based match is not limited to the calendar year.

### `describe '#to_each_weekend'`

- Attaches the tag to `2020-01-04` (Saturday) and `2020-01-05` (Sunday).
- Does not attach the tag to `2020-01-06` (Monday) or `2020-01-10` (Friday).
- Ignores `even_only`: with `EVEN_ONLY? => true`, `2020-01-04` (January, odd month, Saturday) still `include(tag)`.
- Ignores `odd_only`: with `ODD_ONLY? => true`, a February Saturday (for example `2020-02-01`) still `include(tag)`.
- Returns `do_year`.
- Does not raise when `day_name` is absent.
- Raises for a supplied `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => 'Saturday'`, the `INVALID_DAY_NAME` error.
- Raises for an invalid `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay'`, the `INVALID_DAY_NAME` error.
- Raises for a present but nil `day_name`: with `ConfigConstants::KEYS[:DAY_NAME] => nil`, the `INVALID_DAY_NAME` error, matching the weekday method.

### New Fixture `test/each_weekday_config.yml`

Modeled on `test/duplicate_tags_config.yml`. Minimal content so the e2e assertions isolate the two new methods:

```yaml
lg_templates_config:
  base:
    - ""
    - "### Do"
    - ""
    - "```text"
    - "```"
task_templates_config:
  Weekday_Template:
    - Weekday_Tag
  Weekend_Template:
    - Weekend_Tag
tasks_config:
  Every_Weekday:
    method: to_each_weekday
    template: Weekday_Template
  Every_Weekend:
    method: to_each_weekend
    template: Weekend_Template
```

Add `WEEKDAY_PATH: './test/each_weekday_config.yml'` to `TestConstants::CONFIG_FILES` at `test/constants/test_constants.rb:2`.

### `test/e2e/e2e_spec.rb`

- Add a context `'User schedules tasks for each weekday and weekend'` that, in `before :all`, sets `@output_dir`, runs `create_log_file(TestConstants::CONFIG_FILES[:WEEKDAY_PATH], 'DO', 2020, 'ALL', @output_dir)`, parses with `FileParser#get_date_hash_from_do_file`, and cleans up in `after :all`, mirroring the collision context at `:155`.
- `2020-01-06` (Monday) includes `Weekday_Tag` and not `Weekend_Tag`.
- `2020-01-10` (Friday) includes `Weekday_Tag` and not `Weekend_Tag`.
- `2020-01-04` (Saturday) includes `Weekend_Tag` and not `Weekday_Tag`.
- `2020-01-05` (Sunday) includes `Weekend_Tag` and not `Weekday_Tag`.

### Not Tested Here

- Dispatch by method name is generic at `src/services/configured_tasks_service.rb:28` and already covered by `test/spec/services/configured_tasks_service_spec.rb:91`.
- `test/test_config.yml` and the existing byte-identical assertion at `test/e2e/e2e_spec.rb:135` are deliberately unchanged.

## Summary Of Changes

- [ ] `AddTaskService#to_each_weekday` added after `src/services/add_task_service.rb:28`, attaching to days in `Year::WEEKDAY_DAY_NAMES`.
- [ ] `AddTaskService#to_each_weekend` added next to it, attaching to days in `Year::WEEKEND_DAY_NAMES`.
- [ ] Both methods raise `INVALID_DAY_NAME` when the `day_name` key is present, regardless of its value, and apply no `odd_only` or `even_only` filter.
- [ ] `#to_each_weekday` and `#to_each_weekend` unit cases added to `test/spec/services/add_task_service_spec.rb`.
- [ ] README supported-methods list (`README.md:232`) gains `to_each_day`, `to_each_weekday`, and `to_each_weekend` entries.
- [ ] README examples (`README.md:261`) gain `##### to_each_day`, `##### to_each_weekday`, and `##### to_each_weekend` subsections.
- [ ] README Version History (`README.md:604`) gains a dated entry for the two methods.
- [ ] New fixture `test/each_weekday_config.yml`, its `WEEKDAY_PATH` in `test/constants/test_constants.rb:2`, and a new e2e context in `test/e2e/e2e_spec.rb`.
- [ ] No `src/` file other than `src/services/add_task_service.rb` changes; `test/test_config.yml` is untouched.

## Verification Steps

Run these from the repository root. This spec does not run them; the implementer does.

```bash
bundle exec rspec
bundle exec rubocop
```

Confirm the new `describe` blocks and the new e2e context exist and pass, and that the full suite is green with 0 failures and rubocop reports 0 offenses before this is called done. `bundle exec rspec` runs both the unit specs and the e2e specs.

## Open Questions

None. The design decisions (day sets, ignored month filters, adding the weekend sibling, raising on a supplied `day_name`, the unit-plus-e2e test seams, and the README Version History entry) were resolved in the interactive rounds and at sign-off.
