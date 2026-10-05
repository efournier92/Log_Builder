# Tag Order Config

Branch context: no feature branch was created. This spec targets the repository default branch (`master`) of the `Log_Builder` Ruby CLI. The working tree at spec time carries uncommitted changes from the `EachWeekdayScheduling` spec (`docs/specs/2026-10-04_EachWeekdayScheduling.md`), which add `to_each_weekday` and `to_each_weekend` to `src/services/add_task_service.rb`. Every `file:line` anchor below reflects that working tree. If those changes land first, re-locate by method name; the anchor set is otherwise stable.

## Context And Motivation

The tool regenerates a day's task list from configured tasks on every run. The order of the tags within a day is currently the order tasks happen to attach, and a task that attaches later pushes its root tag onto the top of the day.

The observed problem is that tags which should always sit in a fixed place jump around. A monthly or weekly task added after the daily tasks lands its tag at the top of the day. The author wants holidays at the top, then birthdays, then career, then everything else, and the `Body` tag always at the bottom, independent of which schedule happened to add it.

Ordering is currently not configurable at all. There is no order, weight, priority, or grouping key anywhere in the config or code. This spec adds an optional `tag_order_config` list that standardizes root tag order every day, augmenting the existing same-day root tag merge (`docs/specs/2026-10-04_MergeSameDayRootTags.md`) rather than replacing it.

## Glossary

Full definitions live in `docs/GLOSSARY.md`. The load-bearing terms for this spec are restated here so the spec stands alone.

- **Tag**: a single rendered node, for example `Body(...)` or `Git,`.
- **Root tag**: a tag at the top level of a day's list, not nested.
- **Canonical tag node**: the merge-time shape `{ name:, leaf:, children: }`.
- **Tag order**: the configured sequence in `tag_order_config` that fixes root tag positions.
- **`~~OTHER~~` marker**: the reserved list entry that marks where every tag not named in the list renders.

## Current State

- Root tag order is insertion order. `TagMergeService.add_roots` at `src/services/tag_merge_service.rb:18-28` merges same-named roots in place and `unshift`s a new root to the front, so the most recently attached task's root lands on top.
- `ConfiguredTasksService#add_configured_tasks` at `src/services/configured_tasks_service.rb:9-33` reads tasks through `ConfigReaderService#configured_tasks`, which reverses the config order at `src/services/config_reader_service.rb:31-33`. It resolves each task to canonical roots at `src/services/configured_tasks_service.rb:25-26` and dispatches to a schedule method at `:28`.
- Every schedule method routes through `AddTaskService#attach` at `src/services/add_task_service.rb:201-205` (working tree, including the uncommitted EachWeekday additions at `:30-50`). `attach` calls `add_roots` and then `TagMergeService.render` at `src/services/tag_merge_service.rb:65-70`, which prints roots in array order.
- `Day#tag_roots` is a per-day canonical array (`src/models/day.rb:2,8`). `PrinterService#print_tasks` writes the rendered `day.tasks` string at `src/services/printer_service.rb:19`. `day.tasks` and `day.tag_roots` are independent; only `tag_roots` carries structure.
- The config is read leniently: `YAML.load_file` at `src/services/config_reader_service.rb:16` with no schema check, and unknown top-level keys are ignored because every reader fetches only known keys (`src/services/config_reader_service.rb:19-33`).
- Config keys are declared in `src/constants/config_constants.rb:2-23`; the shared error format is `ConfigConstants::ERRORS[:INVALID_CONFIG]` at `src/constants/config_constants.rb:44-48`.
- No order, weight, priority, or grouping key exists today. `CONTENT` at `src/constants/config_constants.rb:12` is only the `{{CONTENT}}` placeholder name; numeric config values today are dates (`month`, `day`, `nth_day`, `n_weeks`) and none affect ordering.
- Order-sensitive tests that must stay green when `tag_order_config` is absent: `test/spec/services/tag_merge_service_spec.rb:65-142` (root and child order), `:230-252` (worked scenario), `test/spec/services/configured_tasks_service_spec.rb:38,44,58,65,79-80,111,136,177`, `test/spec/services/add_task_service_spec.rb:1049-1105` (merge and multi-day isolation), and `test/e2e/e2e_spec.rb:134-152,155-190` (exact rendered blocks).
- `test/spec/services/configured_tasks_service_spec.rb` stubs `ConfigReaderService` with strict doubles at `:85`, `:99-106`, `:125-130`, `:146-149`, and `:167-172`; a new reader method called from `ConfiguredTasksService` must be stubbed on the non-nil doubles.

## Goals

- Add an optional top-level `tag_order_config` list that fixes the order of root tags within every day.
- Render root tags in list order, from the first entry to the last.
- Provide a `~~OTHER~~` marker entry that gives the position of every root tag not named in the list.
- Keep the relative order of root tags that share a position (all unlisted tags at the marker, and all tags when no list applies) unchanged.
- Preserve the current rendered output byte for byte when `tag_order_config` is absent or empty, with the reserved-marker raise as the one exception.
- Keep tag merging by exact name unchanged; apply order after merging.
- Raise a clear configuration error for a malformed list so a typo does not fail silently.

## User Stories

1. As the log author, I want holidays to render at the top of every day they appear, so that special days are the first thing I see.
2. As the log author, I want birthdays to render directly after holidays, so that the top of the page reads holidays, birthdays, career.
3. As the log author, I want career tags to render after birthdays, so that their relative order is fixed.
4. As the log author, I want every tag I did not list to render between career and body, so that routine tags stay in the middle.
5. As the log author, I want the `Body` tag to render at the bottom of every day, so that a later daily or monthly task cannot push it to the top.
6. As the log author, I want a weekly or monthly task's tag to land in its configured slot instead of on top, so that add time no longer decides position.
7. As the log author, I want unlisted tags that share the middle slot to keep the order they already have, so that routine output does not reshuffle.
8. As the log author, I want a day with no configured order to render exactly as it does today, so that adding the feature is safe and opt-in.
9. As the log author, I want the marker to be optional, so that a partial list of just the top or just the bottom tags still works.
10. As the log author, I want the order to apply to root tags only, so that the child order inside a merged tag does not change.
11. As the log author, I want a same-named root tag to merge first and then take its ordered position, so that dedupe and ordering work together.
12. As the log author, I want a clear error when the list has a duplicate or a non-string entry, so that a config typo is caught rather than ignored.
13. As the maintainer, I want the ordering logic in a pure method with no file IO, so that it is fast to test with hand-built trees.
14. As the maintainer, I want `day.tasks` to remain a rendered string and `day.tag_roots` to remain the structured source, so that the printer and existing string-based tests keep working.

## Non-Goals

- Ordering nested children inside a tag. Only root tags are ordered.
- Numeric weights or priorities. The ordered list replaces that paradigm, and no `weight` terminology appears in config, code, or docs.
- Per-task ordering. Order is a global top-level key, not a field on each task.
- Changing the same-day merge behavior. Merging by exact name is unchanged; order runs after it.
- LG mode. LG output is a section template with no tag list, so it is untouched.
- Ordering hand-authored file content. The tool regenerates each day from config only.
- Reordering tags when `tag_order_config` is absent or empty.
- Fixing the unrelated TODO items in `README.md:621-633`.

## Prerequisites

- Ruby 3.4.7 as pinned in `.tool-versions`.
- `bundle install` already run for the repository.
- No schema, database, or external service is involved. This is a single-process CLI.
- The uncommitted `EachWeekdayScheduling` working-tree changes are either committed or left in place; this spec does not depend on them.

## Design Principles

- Keep the ordered list as the single source of order. No weights, no numbers, no second mechanism.
- Resolve order in a pure function over canonical root nodes, with no IO and no dependency on `ConfigReaderService`.
- Apply order after merging, so a merged root takes its ordered slot like any other root.
- Preserve existing output exactly when the feature is unused, by returning the input unchanged for an absent or empty list.
- Stable ties: equal positions never reshuffle. This keeps non-colliding days and the existing merge-slot behavior byte-identical.
- Prefer the smallest diff that satisfies the behavior. No new gems.

## Backend Requirements

### Config Schema

Add one optional top-level key.

```yaml
tag_order_config:
  - Holiday
  - Birthday
  - Career
  - '~~OTHER~~'
  - Body
```

- The value is a YAML list of strings, top entry first.
- `~~OTHER~~` is the reserved marker entry; quote it in YAML as `'~~OTHER~~'`.
- The key may be absent, and that is the default. Absent or empty means no ordering.
- Unknown top-level keys stay ignored as they are today; this key is read only for ordering.

### `ConfigConstants`

Add one key at `src/constants/config_constants.rb:2-23`, after `LG_TEMPLATES:` at line 5:

```ruby
TAG_ORDER: 'tag_order_config',
```

Add the reserved-name marker after the `KEYS` hash at `src/constants/config_constants.rb:23`:

```ruby
TAG_ORDER_MARKER = '~~OTHER~~'.freeze
```

No error constant is added. Ordering errors reuse `ConfigConstants::ERRORS[:INVALID_CONFIG]` at `src/constants/config_constants.rb:44-48`.

### `ConfigReaderService#tag_order`

Add a reader after `configured_tasks` at `src/services/config_reader_service.rb:31-33`:

```ruby
def tag_order
  @config.fetch(ConfigConstants::KEYS[:TAG_ORDER], [])
end
```

- Returns the raw list, or `[]` when the key is absent.
- Performs no type validation, so the pure ordering method owns all validation and its error messages.

### `TagMergeService#order_roots`

Add `require_relative '../constants/config_constants'` near the existing `require_relative '../services/task_printer_service'` at line 1.

Add the pure ordering method after `canonical_roots` (`src/services/tag_merge_service.rb:12-16`), using the shared `ConfigConstants::TAG_ORDER_MARKER`:

```ruby
def self.order_roots(roots, tag_order)
  if roots.any? { |node| node[:name] == ConfigConstants::TAG_ORDER_MARKER }
    raise format(ConfigConstants::ERRORS[:INVALID_CONFIG],
                 "tag name is reserved: #{ConfigConstants::TAG_ORDER_MARKER}")
  end

  return roots if tag_order.nil?
  raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config must be a list') unless tag_order.is_a?(Array)
  return roots if tag_order.empty?

  positions = {}
  unlisted_rank = tag_order.length
  tag_order.each_with_index do |entry, index|
    unless entry.is_a?(String)
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config entries must be strings')
    end
    if positions.key?(entry)
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], "duplicate tag_order_config entry: #{entry}")
    end

    positions[entry] = index
    unlisted_rank = index if entry == ConfigConstants::TAG_ORDER_MARKER
  end

  roots.each_with_index
       .sort_by { |node, index| [positions.fetch(node[:name], unlisted_rank), index] }
       .map(&:first)
end
```

- Rank rule: a listed root takes the index of its entry; an unlisted root takes the marker index, or `tag_order.length` (after the last entry) when the marker is absent.
- The `index` tiebreak makes the sort stable: roots with equal rank keep their current order in `roots`.
- For a non-empty list the method returns a new array; for a `nil` or empty list it returns `roots` unchanged. It never mutates `roots` or any node. Frozen nodes are read only.
- An entry equal to `~~OTHER~~` occupies a position like any other entry and is recorded in `positions` for duplicate detection.
- A root whose name equals the reserved marker is rejected: the method raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag name is reserved: ~~OTHER~~')`. The collision guard runs before the `nil`, non-Array, and empty-list returns, so a configured root named the marker raises even with no order list.

Validation and exact error strings, all through `format(ConfigConstants::ERRORS[:INVALID_CONFIG], <detail>)`:

| Condition | Detail string |
| --- | --- |
| `tag_order` present but not an Array | `tag_order_config must be a list` |
| A non-string entry | `tag_order_config entries must be strings` |
| A repeated string entry, including a repeated marker | `duplicate tag_order_config entry: <entry>` |
| A root name equal to the reserved marker | `tag name is reserved: ~~OTHER~~` |

### `AddTaskService` Changes

Add a constructor before `to_specific_date` at `src/services/add_task_service.rb:7`:

```ruby
def initialize(tag_order = [])
  @tag_order = tag_order
end
```

The default keeps every existing `AddTaskService.new` call site valid, including the test suite.

Update `attach` at `src/services/add_task_service.rb:201-205` to apply order after merge:

```ruby
def attach(day, config, do_year)
  incoming = TagMergeService.canonical_roots(config[ConfigConstants::KEYS[:TAG]])
  day.tag_roots = TagMergeService.add_roots(day.tag_roots, incoming)
  day.tag_roots = TagMergeService.order_roots(day.tag_roots, @tag_order)
  day.tasks = TagMergeService.render(day.tag_roots, do_year.config_file)
end
```

Only this one call site changes. Order is applied after every `add_roots`, so the day's array is always sorted before rendering, including when a later task adds a root.

### `ConfiguredTasksService` Changes

At `src/services/configured_tasks_service.rb:9-20`, move the `AddTaskService` construction below the nil guard and inject the order:

```ruby
def add_configured_tasks(year)
  config_file = year.config_file
  reader = ConfigReaderService.new(config_file)
  tags = reader.configured_tasks

  return if tags.nil?

  add_task_service = AddTaskService.new(reader.tag_order)

  tags.each_value do |config|
    printer = TaskPrinterService.new(config_file)
    method = config[ConfigConstants::KEYS[:METHOD]]
    template = reader.configured_task_templates[config[ConfigConstants::KEYS[:TEMPLATE]]]
    template_variables = config[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]

    template = config[ConfigConstants::KEYS[:TEMPLATE]] if template.nil?

    resolved = printer.resolve_template(template, template_variables)
    config[ConfigConstants::KEYS[:TAG]] = TagMergeService.roots_from_template(resolved)

    add_task_service.public_send(method, year, config)
  end

  year
end
```

`reader.tag_order` is read after the `return if tags.nil?` guard, so the early-return spec at `test/spec/services/configured_tasks_service_spec.rb:84-89` needs no new stub.

### Merge Interaction And Precedence

- Merge runs first, order runs second. Two same-named roots merge into one canonical node, then that node takes its ordered position.
- Order position is by root `name`, matched by exact string equality, the same rule the merge uses at `src/services/tag_merge_service.rb:20`.
- A listed tag that does not appear on a given day is ignored silently.
- With no `tag_order_config`, `order_roots` returns its input array unchanged and the rendered output is byte-identical to today.

### Backfill, Audit, Concurrency

- No backfill. Output files are regenerated on each run.
- No audit trail. Ordering is silent by design.
- No locking or concurrency. The CLI builds one year in a single process.
- `order_roots` allocates a new root array per attach and never reorders shared node objects, so the per-day arrays stay independent. The existing multi-day isolation tests at `test/spec/services/add_task_service_spec.rb:1083-1105` and `test/spec/services/tag_merge_service_spec.rb:214-228` must stay green.

## Frontend And UI Requirements

Not applicable. The deliverable is a CLI and generated Markdown files. There is no console output for ordering. Generated tag indentation and separators must match the current printer exactly, because ordering only changes the order of root strings that `TagMergeService.render` already produces.

## Production Risks And Mitigations

- Wrong slot from a partially listed config. Mitigation: the rank table plus explicit marker and no-marker tests.
- Unstable reordering of unlisted tags. Mitigation: the `index` tiebreak and a dedicated stable-tie test.
- Regression on days with no order config. Mitigation: `order_roots` returns the input unchanged for absent or empty lists, and the existing exact-output e2e assertions stay green.
- Merge and order fighting over the same root. Mitigation: order runs after merge, and a test merges two same-named roots then checks the merged root's ordered slot.
- Merge-slot expectations from the older feature. Mitigation: those tests use `test_config.yml`, which has no `tag_order_config`, so they are unaffected.
- Strict test doubles losing a message. Mitigation: the five double-based contexts in `configured_tasks_service_spec` gain a `tag_order` stub; the early-return double does not need one because the read is below the guard.
- Cost of sorting on every attach. Mitigation: `order_roots` is a no-op for an absent or empty list, and days hold few roots.

## Rollout Plan

Test-first is mandatory for every step: write the failing test, run it and capture the red result, then implement until it passes. Do not write implementation before its failing test exists.

1. Add `ConfigConstants::KEYS[:TAG_ORDER]` and `ConfigReaderService#tag_order` with its spec cases, run them red then green.
2. Add `ConfigConstants::TAG_ORDER_MARKER` and `TagMergeService.order_roots` with its unit spec, run red then green.
3. Add `AddTaskService#initialize(tag_order = [])` and the `order_roots` call in `attach`, with integration cases, run red then green.
4. Wire `ConfiguredTasksService`, add `tag_order` stubs to the non-nil doubles, run the full suite.
5. Add the `test/tag_order_config.yml` fixture, its `ORDER_PATH` constant, and the e2e case, run the full suite.
6. Document `tag_order_config` in `README.md` and add the ToC entry.
7. Run `bundle exec rspec` and `bundle exec rubocop` clean. Single commit on `master`.

## Test Plan

### `test/spec/services/config_reader_service_spec.rb`

- `#tag_order` returns the configured list for a config that defines `tag_order_config`.
- `#tag_order` returns `[]` for a config that does not define it, including the blank config at `TestConstants::CONFIG_FILES[:BLANK_PATH]`.

### `test/spec/services/tag_merge_service_spec.rb` (new `describe '.order_roots'`)

- Returns the input unchanged for a `nil` list.
- Returns the input unchanged for an empty list.
- Places a listed root at its list index, for example `[Body, Alpha]` with `[Alpha, '~~OTHER~~', Body]` becomes `Alpha, Body`.
- Places an unlisted root at the marker index between two listed roots.
- Puts all unlisted roots at the marker position and keeps their incoming relative order, for example `[Alpha, Zeta]` with marker before `Body` stays `Alpha, Zeta`.
- Puts unlisted roots after all listed roots when the marker is absent, for example `[Zeta, Alpha]` with `[Holiday, Body]` becomes `Holiday, Body, Zeta, Alpha`.
- Puts unlisted roots before all listed roots when the marker is the first entry.
- Advances listed roots that appear after the marker past the unlisted block.
- Ignores a listed tag that is absent from the roots.
- Is idempotent: ordering an already ordered array returns the same order.
- Does not mutate the input array.
- Raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config must be a list')` for a non-Array value such as a Hash.
- Raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config entries must be strings')` for a non-string entry such as a nested Array or an Integer.
- Raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'duplicate tag_order_config entry: Holiday')` for a repeated tag name.
- Raises the duplicate error for a repeated `~~OTHER~~` marker.
- Raises `format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag name is reserved: ~~OTHER~~')` when a root is named the reserved marker, including with an empty order list.
- Integration: after `add_roots` merges two same-named roots, `order_roots` places the merged root in its ordered slot.

### `test/spec/services/add_task_service_spec.rb`

- Existing `AddTaskService.new` with no arguments keeps all current order assertions green, including the merge cases at `:1049-1105`.
- New: constructing `AddTaskService.new(['Holiday', '~~OTHER~~', 'Body'])` and attaching a `Holiday` root then a `Body` root yields `day.tag_roots` names `%w[Holiday Body]`, so ordering is required to keep `Body` at the bottom rather than insertion order.
- New: with no order configured, attaching `Holiday` first and `Body` second leaves the later `Body` root on top, yielding `%w[Body Holiday]`.
- New: `day.tasks` reflects the ordered render for a two-root day.

### `test/spec/services/configured_tasks_service_spec.rb`

- Add `allow(reader).to receive(:tag_order).and_return([])` to the non-nil doubles at the `Every_2_Weeks` context (`:99-106`), the canonical-roots context (`:125-130`), the missing-template context (`:146-149`), and the two-task merge context (`:167-172`).
- The early-return context at `:84-89` needs no change; its double returns `configured_tasks: nil` and the read happens below the guard.
- New: a config whose reader reports `tag_order = ['Holiday', '~~OTHER~~', 'Body']` renders a `Body`-then-`Holiday` task pair as `Holiday` then `Body` in `day.tasks`.
- Existing rendered-string assertions at `:38,44,58,65,79-80,111,136,177` stay green because `test_config.yml` has no `tag_order_config`.

### `test/e2e/e2e_spec.rb`

- New context against `TestConstants::CONFIG_FILES[:ORDER_PATH]` for DO 2020, mirroring the collision context at `:155-190`.
- On `2020-01-01`, assert the parsed block equals `"\n\n```text\n"` plus the expected task block with its trailing newline stripped, matching the exact-match style at `:185-188`.
- Expected `day.tasks` for `2020-01-01`:

```text
Holiday(
  New_Year,
),
Birthday(
  Birthday_Person,
),
Career(
  Work_Thing,
),
Alpha,
Zeta,
Body(
  Body_Detail,
),
```

- Assert `Holiday` is the first line and `Body(` is the last root, proving a `to_each_day` `Body` task sorts to the bottom and a once-a-year `Holiday` sorts to the top.
- Existing exact-output e2e assertions for `test_config.yml` at `:136,143-145,148-150` stay green because that fixture has no `tag_order_config`.

### New Fixture `test/tag_order_config.yml`

Create with `test/constants/test_constants.rb` gaining `ORDER_PATH: './test/tag_order_config.yml'` in `CONFIG_FILES`. Fixture content:

```yaml
lg_templates_config:
  base:
    - ""
    - "### Do"
    - ""
    - "```text"
    - "```"
task_templates_config:
  Holiday_Template:
    Holiday:
      - '{{CONTENT}}'
  Birthday_Template:
    Birthday:
      - '{{CONTENT}}'
  Career_Template:
    Career:
      - '{{CONTENT}}'
  Body_Template:
    Body:
      - Body_Detail
  Alpha_Template:
    - Alpha
  Zeta_Template:
    - Zeta
tag_order_config:
  - Holiday
  - Birthday
  - Career
  - '~~OTHER~~'
  - Body
tasks_config:
  Body_Task:
    method: to_each_day
    template: Body_Template
  Holiday_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Holiday_Template
    template_variables:
      - '{{CONTENT}}': New_Year
  Birthday_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Birthday_Template
    template_variables:
      - '{{CONTENT}}': Birthday_Person
  Career_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Career_Template
    template_variables:
      - '{{CONTENT}}': Work_Thing
  Alpha_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Alpha_Template
  Zeta_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Zeta_Template
```

The fixture attaches `Body` last, so without `tag_order_config` `Body` renders on top of `2020-01-01`; with it, `Body` renders last. That contrast is the point of the fixture.

### `test/spec/services/printer_service_spec.rb`

- No change. `print_tasks` still reads the rendered `day.tasks` string at `src/services/printer_service.rb:19`.

## Summary Of Changes

- [ ] `ConfigConstants::KEYS[:TAG_ORDER]` added as `tag_order_config`.
- [ ] `ConfigReaderService#tag_order` added, defaulting to `[]`.
- [ ] `ConfigConstants::TAG_ORDER_MARKER` (`~~OTHER~~`) and pure `TagMergeService.order_roots` added with stable ties, the three validation errors, and the reserved-root-name guard.
- [ ] `AddTaskService#initialize(tag_order = [])` added and `attach` applies `order_roots` after `add_roots`.
- [ ] `ConfiguredTasksService` reads `reader.tag_order` after the nil guard and injects it into `AddTaskService`.
- [ ] `Day`, `PrinterService`, and `TaskPrinterService` unchanged; `day.tasks` stays the rendered string.
- [ ] New `describe '.order_roots'` and `#tag_order` cases, `AddTaskService` integration cases, and updated `ConfiguredTasksService` doubles.
- [ ] New `test/tag_order_config.yml` fixture and `ORDER_PATH` constant, plus the e2e assertion.
- [ ] `README.md` documents `tag_order_config` and the ToC links it; no `weight` terminology anywhere.
- [ ] `docs/GLOSSARY.md` gains the Tag Order term.

## Verification Steps

Run these from the repository root. This spec does not run them; the implementer does.

```bash
bundle exec rspec
bundle exec rubocop
```

Then confirm the fixture manually by running DO mode against `test/tag_order_config.yml` and diffing `2020-01-01` against the expected block above. The full suite must be green with 0 failures before this is called done.

## Open Questions

None. All decisions were resolved in the interactive rounds.

Note: the working tree carries uncommitted `EachWeekdayScheduling` changes that shift line numbers in `src/services/add_task_service.rb` and the test files. This is a coordination note, not an open design question.
