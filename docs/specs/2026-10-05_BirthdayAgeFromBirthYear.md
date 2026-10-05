# Birthday Age From Birth Year

Branch context: no feature branch was created. This spec targets the repository default branch (`master`) of the `Log_Builder` Ruby CLI. Spec time HEAD is `351e467` (`Add Configurable Root Tag Order`) with a clean working tree, so every `file:line` anchor below is stable at that commit.

## Context And Motivation

A birthday is a configured task that runs on a fixed month and day through `to_specific_date`, which currently matches only `month` and `day` and never reads a year (`src/services/add_task_service.rb:11-22`). The rendered tag carries a name and a contact, but not the person's age.

The README has carried an unchecked TODO, "Calculate birthday age from year", since the config-driven rewrite (`README.md:697`). An earlier sample also carried a `year: 1976` key that was removed as dead config because no code read it (`docs/discovery/DISCOVERY.md:49`).

The author wants to optionally record the year a person was born in the task config, and, when it is recorded, have the printed birthday tag show that person's age for the year the tool is building. This is the first task key whose value is computed from the build year rather than supplied literally, so the resolution point and the multi-calendar-year behavior of a `Year` need to be pinned down explicitly.

## Glossary

Full definitions live in `docs/GLOSSARY.md`. The load-bearing terms for this spec are restated here so the spec stands alone.

- **Tag**: a single rendered node, for example `Birthday(...)` or `Age(44,)`.
- **Configured Task**: an entry under `tasks_config` that a scheduling method attaches to one or more days.
- **Build Year**: the integer supplied on the command line, stored as `Year#year_number` (`src/models/year.rb:6`), against which age is calculated.
- **Birth Year**: the optional `birth_year` integer on a `to_specific_date` task recording the calendar year a person was born.
- **Age**: the Build Year minus the Birth Year, rendered as a base-10 integer string.

## Current State

- `AddTaskService#to_specific_date` reads only `month`, `day`, and `is_each`, and attaches when `day.month_day == month_day` and `day.month == month` (or `is_each` is set), across every day of the `Year` (`src/services/add_task_service.rb:11-22`). It never reads a year.
- `Year` holds `year_number` and builds 54 weeks, 378 days, starting in the November or December of `year_number - 1` (`src/models/year.rb:16-28,30-39`). A single `Year` therefore spans parts of three calendar years, and a fixed month and day can occur more than once inside it.
- `Year#initialize` calls `add_configured_tasks` at the end of construction (`src/models/year.rb:27`, `:85-88`), so any config error raised by a task surfaces during `Year.new`, before any mode branch runs.
- `ConfiguredTasksService#add_configured_tasks` receives the whole `Year`, loads the reader, and iterates each task (`src/services/configured_tasks_service.rb:9-30`). For each task it resolves the template once, before any day attaches: `resolved = printer.resolve_template(template, template_variables)` (`:26`), then stores the roots on the config and dispatches `add_task_service.public_send(method, year, config)` (`:27-29`).
- `TaskPrinterService#resolve_template` clones the template and substitutes each `template_variables` entry via `update_content_array` and `gsub!` (`src/services/task_printer_service.rb:112-147,174-176`). Values in `template_variables` are static strings taken verbatim from config; nothing computes them.
- `ConfigConstants::KEYS` maps symbol constants to YAML keys and has no year key (`src/constants/config_constants.rb:2-24`). `ConfigConstants::PLACEHOLDERS` holds `{{` / `}}` / `{{CONTENT}}` (`:28-32`). `CONFIGURED_TASK_METHODS` lists `SPECIFIC_DATE => 'to_specific_date'` (`:34-36`). `ERRORS[:INVALID_CONFIG]` is the shared raise format `'Invalid configuration: %s'` (`:47-51`).
- Config is read leniently and unknown keys are ignored (`src/services/config_reader_service.rb:16`; `docs/discovery/DISCOVERY.md:49`). Validation that does exist raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], ...)` (`src/services/add_task_service.rb:130`).
- `PrinterService#print_do_year` writes every day of the `Year` with no year filter (`src/services/printer_service.rb:44-52`), while `print_do_month` filters on `day.year == year && day.month == month` (`:54-62`). The multi-calendar-year span is therefore visible in DO year output but hidden in DO month output.
- The Birthday fixture task has no `birth_year`: `Birthday_Person` uses `method: to_specific_date`, `month: 1`, `day: 3`, `template: Birthday` (`test/test_config.yml:156-163`), and its expected rendered tag is asserted at `test/spec/services/configured_tasks_service_spec.rb:41-46`.
- The config-driven feature precedent is a new fixture plus a `Year` construction seam, as used for `to_each_weekday` (`test/each_weekday_config.yml:1-19`; `test/constants/test_constants.rb:2-9`).

## Goals

- Add an optional `birth_year` integer to a `to_specific_date` task config.
- When `birth_year` is present, compute the age as the Build Year minus the Birth Year and make it available to the task template as `{{AGE}}`.
- Place the age through the template, so the author controls the label, the position, and the surrounding text.
- Raise `INVALID_CONFIG` when `birth_year` is present but malformed, in the future relative to the Build Year, used on a method other than `to_specific_date`, or when the template does not reference `{{AGE}}`.
- Preserve the rendered output byte for byte for every config that does not use `birth_year`.

## User Stories

1. As the log author, I want to record a birthday's birth year in its task config, so that the printed tag can show how old the person is.
2. As the log author, I want the age calculated against the year I am building, so that a run for 2026 prints 2026 ages.
3. As the log author, I want to position the age inside the birthday tag through my template, so that it reads the way I want.
4. As the log author, I want a typo in `birth_year` to raise a clear error, so that a wrong age is never printed silently.
5. As the log author, I want a `birth_year` in the future relative to the Build Year to raise, so that an impossible age is caught.
6. As the log author, I want a `birth_year` on a non-birthday method to raise, so that the key is not misapplied.
7. As the log author, I want a template that omits `{{AGE}}` to raise when I set `birth_year`, so that I notice the age is not showing.
8. As the log author, I want a birthday with no `birth_year` to render exactly as it does today, so that the feature is opt-in.
9. As the log author, I want a documented age-bearing template example, so that I can copy a working config.
10. As the log author, I want the age to be a plain integer in the tag, so that the output stays in the existing flat text syntax.
11. As the maintainer, I want the age logic at the single point where templates are resolved, so that no scheduler method needs to know about it.
12. As the maintainer, I want the one-shot template resolution kept, so that the per-day render performance work recorded in `docs/discovery/DISCOVERY.md:27` is not undone.
13. As the maintainer, I want the existing fixture and its byte-identical expectations left untouched, so that current characterization tests stay meaningful.
14. As the maintainer, I want a dedicated fixture for the age case, so that the e2e byte-identical outputs do not shift.

## Non-Goals

- Computing a completed age as of the exact birthday date. The rule is strictly Build Year minus Birth Year, per the decision below.
- Per-day variation of age inside one run. All occurrences of the tag in one `Year` use the one Build Year value.
- Changing scheduling. `to_specific_date` still matches on `month` and `day` only; `birth_year` is metadata and does not filter which days attach.
- Suppressing the extra adjacent-calendar-year occurrence that a 378-day `Year` already produces. That is existing behavior and out of scope.
- Supporting `birth_year` on any method other than `to_specific_date`.
- Reusing the removed `year` key name. The new key is `birth_year`.
- Any UI, since the tool is a CLI that writes Markdown files.

## Prerequisites

- A Ruby toolchain able to run `bundle exec rspec` and `bundle exec rubocop` at HEAD `351e467`.
- The existing template substitution path, `TaskPrinterService#resolve_template` (`src/services/task_printer_service.rb:138-147`), unchanged.
- A decision on where age resolution runs, settled here: at `ConfiguredTasksService#add_configured_tasks` (`src/services/configured_tasks_service.rb:18-30`), before the existing `resolve_template` call.

## Design Principles

- Resolve once, before attach. The Build Year is constant for a run, so age is computed once per task at the existing resolution point. This preserves the one-shot resolution that the merge render fix depends on (`docs/discovery/DISCOVERY.md:27`).
- Place through the template, do not restructure the tag. The system supplies a value; the template decides the text. No node is appended automatically.
- Fail loud on a partial feature. Setting `birth_year` without a template that can show it is an error, not a silent no-op.
- Opt-in and byte-identical when absent. No existing config changes behavior.
- Reuse existing constants and error format. No new error class, no new dependency.

## Backend Requirements

### Config Schema

- Add `BIRTH_YEAR: 'birth_year'` to `ConfigConstants::KEYS` in `src/constants/config_constants.rb:2-24`.
- The value is an optional Integer on a task under `tasks_config`. YAML bare numbers parse to Integer; quoted numbers parse to String and are rejected by validation.
- The key is only valid when the task's `method` is `to_specific_date`, the value of `ConfigConstants::CONFIGURED_TASK_METHODS[:SPECIFIC_DATE]` (`src/constants/config_constants.rb:35`).

### Placeholder

- Add `AGE: '{{AGE}}'` to `ConfigConstants::PLACEHOLDERS` in `src/constants/config_constants.rb:28-32`.
- The author writes `{{AGE}}` somewhere in the task's template (named or inline), the same way `{{NAME}}` is written today (`test/test_config.yml:80-83`).
- The token is substituted by the existing `resolve_template` path. No new substitution mechanism is introduced.

### Resolution Logic

The age is computed in `ConfiguredTasksService#add_configured_tasks`, at the point where `template`, `template_variables`, and the `year` are all in scope, immediately before the existing call at `src/services/configured_tasks_service.rb:26`. The following is the intended shape, anchored to the current loop at `:18-30`:

```ruby
tags.each_value do |config|
  printer = TaskPrinterService.new(config_file)
  method = config[ConfigConstants::KEYS[:METHOD]]
  template = reader.configured_task_templates[config[ConfigConstants::KEYS[:TEMPLATE]]]
  template_variables = config[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]

  template = config[ConfigConstants::KEYS[:TEMPLATE]] if template.nil?

  template_variables = with_birth_year(config, method, template, template_variables, year)

  resolved = printer.resolve_template(template, template_variables)
  config[ConfigConstants::KEYS[:TAG]] = TagMergeService.roots_from_template(resolved)

  add_task_service.public_send(method, year, config)
end
```

- `with_birth_year` returns `template_variables` unchanged when the task config does not have the `birth_year` key.
- When the key is present, `with_birth_year` validates in this exact order and raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], <message>)` on the first failure:
  1. Method gate: `method != ConfigConstants::CONFIGURED_TASK_METHODS[:SPECIFIC_DATE]` raises `'birth_year is only supported with to_specific_date'`.
  2. Type: `birth_year` is not an `Integer` raises `'birth_year must be an integer'`. A present-but-nil value, such as an empty `birth_year:` line, fails here.
  3. Range: `birth_year > year.year_number` raises `'birth_year cannot be in the future'`.
  4. Placeholder: the template does not contain the literal `{{AGE}}` token raises `'birth_year requires {{AGE}} in the template'`.
- On success the age is `year.year_number - birth_year`, always non-negative given the range check.
- The returned variables are the existing `template_variables` with one appended entry, `{ ConfigConstants::PLACEHOLDERS[:AGE] => age.to_s }`. When `template_variables` is nil it becomes a one-element array. The append uses a new array so the config is not mutated in place. If `template_variables` is present but not an Array, that is a pre-existing malformed-config case and no new handling is added.
- Placeholder detection is a deep scan of the template object for any String containing `{{AGE}}`, checking both Hash keys and values and every Array element. The scan runs against the unresolved template, before `resolve_template`. Put it in a private `ConfiguredTasksService` helper, for example `template_includes?(node, token)`, with no file IO and no side effects.
- A template that is a bare String because a named template is missing has no `{{AGE}}`, so the placeholder check raises. This is acceptable: a `birth_year` task with an unresolvable template is already a broken config, and the message names `{{AGE}}` as the missing piece.

### Validation Order Rationale

The method gate runs first so a `birth_year` on, for example, a `to_each_day` task raises the scope error regardless of the value. The remaining three checks are independent, each with one dedicated test, so their order matters only when a config is wrong in more than one way at once; the order above is then deterministic.

### Caller Refactor Points

- `src/services/configured_tasks_service.rb:18-30`: replace the direct `resolve_template` call at `:26` with the `with_birth_year` call plus the existing resolve, as shown above. Add the private `with_birth_year` and `template_includes?` helpers below `add_configured_tasks`.
- No change to `AddTaskService#attach` (`src/services/add_task_service.rb:206-211`). The rendered `config[:tag]` already carries the substituted age by the time a scheduler runs.
- No change to `TaskPrinterService`. Its `resolve_template` contract is unchanged; it simply receives one more variable when the feature is used.
- No change to `Year`, `Day`, `PrinterService`, or any scheduler method.

### Migration, Backfill, Audit, Concurrency

- No schema migration, no backfill, and no one-off task. The feature is read at task-resolution time only.
- No audit trail is added. There is no persistence layer; each run regenerates output from config.
- No concurrency or locking work. The CLI is single-threaded and each `Year` is built once.
- Because `Year#initialize` resolves tasks regardless of mode (`src/models/year.rb:27`), a malformed `birth_year` raises even for LG mode runs, consistent with how any other task config error already behaves.

## Frontend / UI Requirements

- There is no browser or window UI. The user-facing surface is the rendered Markdown and the README.
- Rendered output: for a `to_specific_date` task with `birth_year` and a template that contains `Age({{AGE}},)`, the birthday root tag gains that child in template order. With `Birthday_With_Age` defined as `Name({{NAME}},)`, `Contact({{CONTACT}},)`, `Age({{AGE}},)` and `birth_year: 1976`, a 2020 build renders:

```text
Birthday(
  Name(AbeLincoln,),
  Contact(honest_abe_1809@hotmail.com,),
  Age(44,),
),
```

- There are no enum-to-label mappings in this feature; the value is a plain integer.
- README changes required:
  - `### Birthdays` (`README.md:647-658`): keep the existing birth-year-less example and add a second template, `Birthday_With_Age`, that appends `- 'Age({{AGE}},)'`, plus a task example using `birth_year` and that template. State that the template must reference `{{AGE}}` when `birth_year` is set.
  - `## Version History` (`README.md:660`): add an entry dated 2026-10-05 describing the optional `birth_year` and the `{{AGE}}` placeholder.
  - `## TODO Items` (`README.md:686-698`): check off `- [ ] Calculate birthday age from year` (`README.md:697`).

## Production Risks And Mitigations

- Shared-template trap. If a task without `birth_year` uses a template that contains `{{AGE}}`, the token is left literal in the output because no variable replaces it. Mitigation: document a dedicated age-bearing template (`Birthday_With_Age`) and keep the shared `Birthday` template age-free, per the docs decision. The raise only fires when `birth_year` is present, so this trap is documentation-level, not code-level.
- Multi-calendar-year occurrence. A 378-day `Year` contains the fixed month and day in more than one calendar year, so a birthday can attach more than once and, in DO year output (`src/services/printer_service.rb:44-52`), render more than once. All occurrences use the one Build Year, so an adjacent-year occurrence can show an age one year off. This is accepted by the Build Year decision and recorded as a non-goal; the test plan pins the behavior so it cannot drift silently.
- New raise surfaces during `Year.new`. A malformed `birth_year` now aborts the whole run, including LG mode, because tasks resolve at `Year` construction. Mitigation: the error message names the key and the reason, matching the existing `INVALID_CONFIG` style.
- Unknown-key leniency regression. When `birth_year` is present, the template is now inspected for `{{AGE}}`, which is a new failure mode for the otherwise lenient reader. Mitigation: the check only runs when the author opts in with `birth_year`, so no existing config is affected.

## Rollout Plan

- One commit on `master`, no branch required, no migration step, no feature flag.
- Ship the code, the new fixture, the new test constants, the README updates, and the checked-off TODO together so docs and behavior land in the same revision.
- After verification, the operator may index the load-bearing decision from this spec as a `[decision]` entry in `docs/discovery/DISCOVERY.md`; this spec does not write that index.
- Rollback is a straight revert because no data or persisted state changes.

## Test Plan

### Fixture And Constants

- Add `test/birthday_age_config.yml` mirroring the minimal shape of `test/each_weekday_config.yml`:

```yaml
task_templates_config:
  Birthday_With_Age:
    Birthday:
      - 'Name({{NAME}},)'
      - 'Contact({{CONTACT}},)'
      - 'Age({{AGE}},)'
tasks_config:
  Birthday_Age_Person:
    method: to_specific_date
    month: 1
    day: 3
    birth_year: 1976
    template: Birthday_With_Age
    template_variables:
      - '{{NAME}}': PersonsName
      - '{{CONTACT}}': 000-000-0000
```

- Add `CONFIG_FILES[:BIRTHDAY_AGE_PATH] = './test/birthday_age_config.yml'` to `test/constants/test_constants.rb:2-9`.
- Do not touch `test/test_config.yml`. The e2e outputs stay byte-identical.

### `test/spec/services/configured_tasks_service_spec.rb` (new context)

Seam: `Year.new(build_year, TestConstants::CONFIG_FILES[:BIRTHDAY_AGE_PATH])`, then assert on `day.tasks`, following `:9-46`. For raise cases, stub `ConfigReaderService` as in `:85-113` and build `Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH])` after stubbing, so no fixture is needed.

- Happy path, exact age: `Year.new(2020, BIRTHDAY_AGE_PATH)`, find the day with `d.year == 2020 && d.month == 1 && d.month_day == 3`, expect `day.tasks` to include `"Birthday(\n  Name(PersonsName,),\n  Contact(000-000-0000,),\n  Age(44,),\n),"` (2020 minus 1976).
- Build-year reference: `Year.new(2021, BIRTHDAY_AGE_PATH)`, find `d.year == 2021 && d.month == 1 && d.month_day == 3`, expect `Age(45,)`.
- Adjacent-year occurrence: `Year.new(2020, BIRTHDAY_AGE_PATH)`, find `d.year == 2021 && d.month == 1 && d.month_day == 3`, expect `Age(44,)`, the same Build Year value, pinning the accepted non-goal.
- Age zero: with a stubbed task where `birth_year == 2020` and build year 2020, expect `Age(0,)`.
- Raise, non-integer: `birth_year: '1976'` (String) raises `Invalid configuration: birth_year must be an integer`.
- Raise, nil value: `birth_year` key present with nil raises `Invalid configuration: birth_year must be an integer`.
- Raise, future: `birth_year: 2021` with build year 2020 raises `Invalid configuration: birth_year cannot be in the future`.
- Raise, missing placeholder: a template without `{{AGE}}` and a valid integer `birth_year` raises `Invalid configuration: birth_year requires {{AGE}} in the template`.
- Raise, wrong method: `method: to_each_day` with `birth_year` present raises `Invalid configuration: birth_year is only supported with to_specific_date`.

### Regression

- The full existing suite, including `test/spec/services/configured_tasks_service_spec.rb:41-46` and the e2e exact-output assertions, must stay green with no expectation edits. A birthday task without `birth_year` renders byte for byte as before.

## Summary Of Changes

- [ ] `ConfigConstants::KEYS` gains `BIRTH_YEAR: 'birth_year'` (`src/constants/config_constants.rb`).
- [ ] `ConfigConstants::PLACEHOLDERS` gains `AGE: '{{AGE}}'` (`src/constants/config_constants.rb`).
- [ ] `ConfiguredTasksService#add_configured_tasks` injects the computed age variable before resolving the template, with validation and exact error messages (`src/services/configured_tasks_service.rb`).
- [ ] New fixture `test/birthday_age_config.yml`.
- [ ] New `TestConstants::CONFIG_FILES[:BIRTHDAY_AGE_PATH]` (`test/constants/test_constants.rb`).
- [ ] New test context in `test/spec/services/configured_tasks_service_spec.rb` covering the happy path, build-year reference, adjacent-year occurrence, zero age, and the four raise conditions.
- [ ] README Birthdays section documents `Birthday_With_Age` and the `birth_year` key (`README.md`).
- [ ] README Version History entry dated 2026-10-05 (`README.md`).
- [ ] README TODO "Calculate birthday age from year" checked off (`README.md`).
- [ ] `docs/GLOSSARY.md` gains Birth Year and Age entries.

## Verification Steps

- Run `bundle exec rspec` from `/Users/e/mnt/bnk/cs/Log_Builder`; the full suite passes with zero failures and no modified existing expectations.
- Run `bundle exec rubocop`; zero offenses.
- Manually confirm a sampled run: build `Year.new(2020, './test/birthday_age_config.yml')` and check the day with `year == 2020, month == 1, month_day == 3` renders `Age(44,)`, and that a task config without `birth_year` renders unchanged.
- Run the markdown linter on this spec if the repository wires one; the spec must satisfy the project Markdown style before the implementer starts.
- Do not commit or push; that is the user's call through their normal ship step.

## Open Questions

None. All frontier decisions were resolved with the user: key name `birth_year`, `{{AGE}}` placeholder with a raise when unused, age against the Build Year, scope limited to `to_specific_date`, `INVALID_CONFIG` on malformed or future values, a new fixture at the `Year` seam, and a dedicated age-bearing documented template.
