# Merge Same-Day Root Tags

Branch context: no feature branch was created. This spec targets the repository default branch (`main`) of the `Log_Builder` Ruby CLI. The example that anchors the requirements is `docs/examples/DuplicateTags_Example.md`.

## Context And Motivation

The tool builds a daily task list from configured tasks. Each configured task renders a tag tree and the tag is attached to every day its schedule matches (`src/services/configured_tasks_service.rb:16`, `src/services/add_task_service.rb:5`). Nothing inspects tag names, so when two configured tasks render the same root tag on the same day, the day ends up with two sibling root tags.

The observed failure is in `docs/examples/DuplicateTags_Example.md`. Three `Body` tags appear near the top of the day and a fourth `Body(Vitamins_Take(...), Vc(...))` appears at the bottom. The expected output is a single `Body` tag at the bottom containing the union of all four, with `Ears` merged (including a deduped `Drops_CarbamidePeroxide_Apply`). The same thing happens when a monthly task introduces a `Groom` tag at the top that should instead live inside the preexisting `Groom` at the bottom.

## Glossary

Full definitions live in `docs/GLOSSARY.md`. The load-bearing terms for this spec are restated here so the spec stands alone.

- **Tag**: a single rendered node, for example `Body(...)` or `Git,`.
- **Root tag**: a tag at the top level of a day's list, not nested.
- **Internal node**: a tag with children, rendering with parentheses.
- **Leaf node**: a tag with no children, rendering as text plus a comma.
- **Configured task**: an entry under `tasks_config` that a scheduling method attaches to days.
- **Canonical tag node**: the merge-time shape `{ name:, leaf:, children: }`.

## Current State

- `Day#tasks` is a `String` with an accessor at `src/models/day.rb:2`, initialized to `''` when `Year` builds each day at `src/models/year.rb:43`.
- `ConfigReaderService#configured_tasks` returns `tasks_config` reversed at `src/services/config_reader_service.rb:32`, so the first config entry is processed last.
- `ConfiguredTasksService#add_configured_tasks` renders each task to a string with `printer.print_from_template` (`src/services/configured_tasks_service.rb:25`), stores it under `config['tag']` at `src/services/configured_tasks_service.rb:24`, then dispatches to an `AddTaskService` schedule method at `src/services/configured_tasks_service.rb:27`.
- `TaskPrinterService#print_from_template` clones the template, substitutes `template_variables`, and prints to a string at `src/services/task_printer_service.rb:135`.
- Every `AddTaskService` schedule method prepends that string to the day with `day.tasks.prepend(new_tag)` at `src/services/add_task_service.rb:15,27,39,64,86,149,165,183`.
- `PrinterService#print_tasks` writes `day.tasks.to_s` at `src/services/printer_service.rb:19`.
- The result is plain string concatenation. Identical or same-named tags are never combined.
- The README already lists the intent as a TODO, "Overwrite same-named tags for a day", at `README.md:602`.
- Tests read `day.tasks` as a rendered string, for example `test/spec/services/configured_tasks_service_spec.rb:18` and the `include` assertions across `test/spec/services/add_task_service_spec.rb` (for example `:42`). `test/spec/services/printer_service_spec.rb:69` feeds a `tasks:` string double.
- Known adjacent gap, not addressed here: composed `{{TASK.*}}` template references are never resolved and pass through literally (`src/services/task_printer_service.rb:48`; see the `[trap]` entry in `docs/discovery/DISCOVERY.md`).

## Goals

- When two or more configured tasks render the same-named root tag on the same day, produce one merged root tag.
- Merge recursively: same-named internal nodes merge at every level, and exact-duplicate leaves collapse.
- Place the incoming task's children before the existing children at each merged level.
- Keep the merged root in the slot of its bottom-most occurrence, never move it to the top.
- Keep every other root tag's relative order unchanged.
- Preserve the current rendered output byte for byte on days that have no collision.
- Apply silently and unconditionally in DO mode, with no configuration changes required.

## User Stories

1. As the log author, I want a monthly `Groom` task to merge into the existing `Groom` tag at the bottom, so that I see one `Groom` block instead of a stray root tag at the top.
2. As the log author, I want two identical `Body` tags to collapse into one, so that repeated schedules do not duplicate content.
3. As the log author, I want a third `Body` with an extra `Camera_Wax_Remove` child to merge into the existing `Body`, so that I see the union of all children.
4. As the log author, I want the duplicate leaf `Drops_CarbamidePeroxide_Apply` to appear once after merging, so that merged output is not noisy.
5. As the log author, I want merged internal children to appear before the preexisting children, so that newly added content is visible at the top of the tag.
6. As the log author, I want the merged tag to stay where the preexisting tag was, so that tags below it do not jump around.
7. As the log author, I want non-colliding tags to render exactly as they do today, so that existing logs do not change unexpectedly.
8. As the log author, I want merges to happen for every configured task automatically, so that I do not have to opt in per task.
9. As the log author, I want the tool to stay silent during merges, so that generated files and console output remain clean.
10. As the log author, I want a same-named internal tag and leaf tag to keep both values, so that a rare collision does not lose data.
11. As the maintainer, I want the merge logic isolated in a pure service with no file IO, so that it is fast to test with hand-built trees.
12. As the maintainer, I want `day.tasks` to remain a rendered string, so that the task printer and most existing string-based tests keep working.

## Non-Goals

- LG mode. LG output is a section template, not a tag list, and is untouched.
- A per-task or global opt-in flag. Merging is always on (user decision Q5).
- Overwriting a same-named tag. This spec supersedes that TODO with merging (user decision Q7).
- Merging across days. Merging is always scoped to a single day.
- Merging with hand-authored file content. The tool regenerates each day from config only.
- Fixing the unresolved `{{TASK.*}}` composed-template gap. It is a separate known trap.
- Reformatting, reordering, or re-indenting tags that do not collide.
- Deduping whitespace, comments, or non-tag text.

## Prerequisites

- Ruby 3.4.7 as pinned in `.tool-versions`.
- `bundle install` already run for the repository.
- No schema, database, or external service is involved. This is a single-process CLI.

## Design Principles

- Separate the merge decision from rendering. The merge service is pure data in, data out, with no IO and no dependency on `ConfigReaderService`.
- Keep the task printer as the only renderer. Merging never hand-writes tag text, so indentation and separators stay correct.
- Keep `day.tasks` as a rendered `String`, derived from a structured accumulator. This preserves the printer contract and most existing tests.
- Reuse the existing reversed iteration and prepend order so non-colliding output is byte-identical.
- Prefer the smallest diff that satisfies the behavior. No new gems.

## Backend Requirements

### Canonical Tag Node

All merging operates on a canonical node:

```ruby
{ name: String, leaf: Boolean, children: Array<CanonicalTagNode> }
```

- `leaf: true` means a leaf node whose `name` is its exact rendered text, and `children` is empty.
- `leaf: false` means an internal node; `children` is ordered, incoming-first after a merge.
- Node identity for matching is `name` alone. For a leaf, `name` is the full text, so two leaves match only when their text is identical. This is how Q8 is satisfied without a special case.
- A name collision between an internal node and a leaf resolves with the internal as the keeper and the leaf kept as a child (user decision Q11).

### New Service `TagMergeService`

Create `src/services/tag_merge_service.rb`. It requires `../services/task_printer_service`. Public methods:

- `roots_from_template(template)` returns `Array<CanonicalTagNode>`.
  - Hash template: one node per key via `to_node(key, value)`.
  - Array template: one leaf node per element.
  - String template: one leaf node named by the string.
  - `nil`: empty array.
  - `to_node(name, value)`: `nil` value yields a leaf named `name`; a Hash value yields an internal whose children are `value.map { to_node(k, v) }`; an Array value yields an internal whose children are leaf nodes, one per element; any other scalar yields an internal with a single leaf child.
- `canonical_roots(value)` accepts either a `String` (returns one leaf node) or an already-canonical `Array` (returns it unchanged). This exists so `AddTaskService` stays compatible with specs that pass a raw string.
- Immutability is a hard requirement. `merge_nodes` and `merge_children` allocate new nodes and new child arrays and must never mutate `a`, `b`, or any nested node. `add_roots` may mutate only the day-owned `existing` array (its `unshift` and index assignment); it must never mutate `incoming` or the nodes it holds. `attach` must not mutate `incoming` either. Reason: `ConfiguredTasksService` computes one canonical roots array per task and passes the same node objects to every matching day, so an in-place merge aliases days together and accumulates duplicate children across the run. Freeze nodes where practical and cover this with the multi-day isolation test in the test plan.
- `add_roots(existing, incoming)` mutates and returns `existing`. It iterates `incoming.reverse_each`, finds the first existing node with the same `name`, replaces that slot with `merge_nodes(existing[idx], node)` (index preserved), and otherwise `unshift`s the incoming node. Reverse iteration preserves the incoming block's order at the front for non-colliding multi-root tasks.
- `merge_nodes(a, b)` requires equal `name` and returns a new node by this table:

| Existing (`a`) | Incoming (`b`) | Result |
| --- | --- | --- |
| internal | internal | new node, same name, `children = merge_children(a.children, b.children)` |
| leaf | leaf | `a` (identical text, deduped) |
| internal | leaf | a copy of the internal with `b` prepended as a child |
| leaf | internal | a copy of the internal with `a` prepended as a child |

- `merge_children(existing, incoming)` returns a new ordered array where incoming children come first, preserving incoming order, then existing children that had no incoming counterpart.
  - Build the result list. For each incoming child, match the first node already in the result, or the first not-yet-consumed existing child, with the same `name`; place `merge_nodes(matched, child)` in the result. If nothing matches, add the incoming child to the result.
  - Append any not-yet-consumed existing child whose `name` is not already present in the result.
  - This yields recursive merging and exact-leaf dedupe (user decisions Q2 and Q3).
- `render(roots, config_file)` returns a `String`. For each root, it builds a printer tree and calls a fresh `TaskPrinterService.new(config_file).print(tree)`, then joins the results.
  - Leaf root renders as `[root[:name]]`.
  - Internal root renders as `{ root[:name] => printable_children(root[:children]) }`.
  - `printable_children(children)` returns an Array of leaf text when every child is a leaf, so the printer takes its leaf path (`src/services/task_printer_service.rb:31`) and does not run placeholder resolution. When at least one child is internal, it returns an ordered Hash mapping each leaf child `name` to `nil` and each internal child `name` to its own printable children.
  - A fresh printer per root is required because `TaskPrinterService` accumulates `@output` and counters (`src/services/task_printer_service.rb:9`).

### `TaskPrinterService#resolve_template`

Add a method at `src/services/task_printer_service.rb` next to `print_from_template` (`:135`):

```ruby
def resolve_template(template, template_variables)
  return template if template_variables.nil?

  template_to_update = Marshal.load(Marshal.dump(template))
  update_content_hash(template_to_update, template_variables)
  template_to_update
end
```

Then refactor `print_from_template` to call `print(resolve_template(template, template_variables))` and return the printed string. Behavior for existing callers is unchanged.

### `ConfiguredTasksService` Changes

At `src/services/configured_tasks_service.rb:22-25`, replace the string render with a resolved tree and canonical roots:

```ruby
resolved = printer.resolve_template(template, template_variables)
config[ConfigConstants::KEYS[:TAG]] = TagMergeService.roots_from_template(resolved)
```

Add `require_relative './tag_merge_service'` near the other requires. The `template` fallback at `:22` changes behavior and this is intended: when a configured task names a template that is missing from `task_templates_config` and supplies no inline template, `template` stays the String name, which previously raised inside the printer (`String#each`) and now becomes a single leaf node named by that string through `roots_from_template`. Add the fallback test named in the test plan.

> Superseded by `docs/specs/2026-10-08_ConfigLoadValidation.md`: a String `template` naming no entry now raises `ConfigReaderService::InvalidConfigError` at load instead of rendering a leaf; inline Hash/Array templates keep working.

### `AddTaskService` Changes

Add `require_relative './tag_merge_service'`. Add a private helper:

```ruby
def attach(day, config, do_year)
  incoming = TagMergeService.canonical_roots(config[ConfigConstants::KEYS[:TAG]])
  day.tag_roots = TagMergeService.add_roots(day.tag_roots, incoming)
  day.tasks = TagMergeService.render(day.tag_roots, do_year.config_file)
end
```

Replace each `new_tag = config[ConfigConstants::KEYS[:TAG]]` local and each `day.tasks.prepend(new_tag)` call with a call to `attach(day, config, do_year)` guarded by the existing condition. Exact sites:

| Method | Remove local at | Replace prepend at |
| --- | --- | --- |
| `to_specific_date` | `:9` | `:15` |
| `to_each_day` | `:24` | `:27` |
| `to_each_xday` | `:36` | `:39` |
| `to_nth_xday_in_month` | `:50` | `:64` |
| `to_last_xday_in_month` | `:77` | `:86` |
| `to_xday_every_n_weeks` | `:142` | `:149` |
| `to_easter` | `:158` | `:165` |
| `to_good_friday` | `:172` | `:183` |

Each replacement preserves the surrounding `if` condition, for example `attach(day, config, do_year) if (day.month == month || is_each) && day.month_day == month_day`.

### `Day` Changes

At `src/models/day.rb:2`, add `tag_roots` to the accessor list. In `initialize` (`:5`), initialize `@tag_roots = []`. Keep `@tasks = tasks` and the existing constructor signature so `Year#add_next_week` (`src/models/year.rb:43`) does not change.

### `PrinterService` Changes

None required. It keeps writing `day.tasks.to_s` (`src/services/printer_service.rb:19`), and `day.tasks` remains the rendered string.

### Config Schema, Backfill, Audit, Concurrency

- No config schema change. `tasks_config`, `task_templates_config`, and `lg_templates_config` keep their current shapes.
- No backfill. Output files are regenerated on each run.
- No audit trail. Merge is silent by design (user decision Q9).
- No locking or concurrency. The CLI builds one year in a single process.

## Frontend And UI Requirements

Not applicable. The deliverable is a CLI and generated Markdown files. There is no console output on merge (user decision Q9). Generated tag indentation and separators must match the current printer exactly, including the trailing `,\n` per root.

## Production Risks And Mitigations

- Formatting drift from the new render path. Mitigation: render each root through the existing `TaskPrinterService`, and add a characterization test asserting a non-colliding day is byte-identical to a captured current output.
- Wrong merge slot. Mitigation: `add_roots` replaces only the matched index in the day-owned array and only `unshift`s genuinely new roots; test the `Body` then `Zeta` ordering.
- Leaf versus internal name collision. Mitigation: the precedence table plus a dedicated test.
- Performance regression from re-rendering a day after every insertion. Mitigation: days hold few tags; if it ever matters, render only in `PrinterService`. Not needed now.
- `Marshal` on the resolved template. Mitigation: keep the existing `Marshal.load(Marshal.dump(...))` pattern already used at `src/services/task_printer_service.rb:139`.
- Test churn from the `day.tasks` type. Mitigation: keep `day.tasks` a `String`; only `day.tag_roots` is new.
- Composed `{{TASK.*}}` placeholders routed through the new render path. Mitigation: `printable_children` keeps all-leaf children as an Array so the printer uses its leaf path and no new debug output appears; covered by a test asserting the `Composed_Task` render is unchanged.

## Rollout Plan

Test-first is mandatory for every step: write the failing test, run it and capture the red result, then implement until it passes. Do not write implementation before its failing test exists.

1. Add `TagMergeService` and its unit spec with no callers, verify the spec passes.
2. Add `TaskPrinterService#resolve_template` and its spec.
3. Wire `ConfiguredTasksService`, `AddTaskService`, and `Day`, run the full suite.
4. Add the collision fixture and the e2e assertion, run the full suite.
5. Remove the README TODO at `README.md:602` and document the merge behavior under Configuration.
6. Single commit on `main`. No flag, no migration, no deploy step.

## Test Plan

### `test/spec/services/tag_merge_service_spec.rb` (new)

- `roots_from_template` returns one leaf node for a String template.
- `roots_from_template` splits a multi-key Hash into one node per key.
- `roots_from_template` turns an Array template into one leaf node per element.
- `roots_from_template` maps a `nil` value to a leaf named by the key.
- `roots_from_template` maps a scalar hash value (for example `{ Milligrams: 4000 }`) to an internal with a single leaf child named by the scalar.
- `canonical_roots` returns one leaf node for a `String`.
- `canonical_roots` returns an already-canonical `Array` unchanged.
- `add_roots` prepends a new root to the front.
- `add_roots` preserves the order of a two-root incoming block.
- `add_roots` merges two same-named internal roots and keeps the existing index (slot).
- `add_roots` does not mutate `incoming` or the nodes it holds.
- `add_roots` dedupes two identical leaf roots.
- `add_roots` keeps two different-text leaf roots as separate nodes.
- `add_roots` resolves an internal versus leaf name collision with the internal kept and the leaf prepended as a child.
- `add_roots` resolves the reverse order (existing leaf, incoming internal) with the internal kept and the leaf prepended as a child.
- `add_roots` resolves an internal versus leaf child collision at a nested level, not only at the root.
- `merge_nodes` prepends incoming children before existing children and does not mutate either input.
- `merge_children` recurses into a shared internal child and dedupes its exact leaves.
- `merge_children` dedupes an exact duplicate leaf across incoming and existing.
- Regression guard: `merge_children([Vitamins_Take], [Ears])` equals `[Ears, Vitamins_Take]`, failing loudly if incoming children are ever appended after existing.
- `render` reproduces `Level_1(\n  Level_2,\n),\n` for a two-level internal root.
- `render` reproduces `Task_Name,\n` for a leaf root.
- `render` returns `''` for an empty roots array.
- `render` of a tree whose leaf children contain `{{TASK.*}}` returns the same literal text as the current printer and emits no additional stdout.
- Immutability: calling `add_roots` twice with the same `incoming` against two different day arrays produces two independent trees, and a later merge into one does not change the other. This is the multi-day isolation regression test.
- Worked scenario from `docs/examples/DuplicateTags_Example.md`: given the four `Body` contributions, output is one `Body` with `Ears(Drops, Camera_Wax_Remove)` first, then `Vitamins_Take`, then `Vc`.

### `test/spec/services/task_printer_service_spec.rb`

- `resolve_template` returns the substituted tree.
- `resolve_template` does not mutate the input template.
- `resolve_template` returns the template unchanged when `template_variables` is `nil`.
- `print_from_template` still returns the same string as before the refactor (existing cases at `:266` and `:280` must stay green).

### `test/spec/services/add_task_service_spec.rb`

- Existing `day.tasks` `include` assertions stay green because a raw `'Test_Tag'` is accepted and rendered as `Test_Tag,\n`.
- New: adding a tag with an internal body value stores a matching `day.tag_roots` entry.
- New: adding two same-named tags to the same day yields one root node whose children are merged.
- New: a `to_each_day`-style attach of the same config to multiple days leaves each day's tree independent; merging an extra tag into day one does not change day two. This is the cross-day aliasing regression test.

### `test/spec/services/configured_tasks_service_spec.rb`

- Existing rendered-string assertions stay green after wiring `resolve_template` and `roots_from_template`.
- `config['tag']` is a canonical roots array when `add_configured_tasks` returns.
- New: a task whose named template is missing and has no inline template renders as a single leaf named by the template string instead of raising.
- New: two tasks that render the same root on the same day produce one merged root in the rendered `day.tasks`.
- New: a task scheduled across many days does not accumulate duplicate children on later days when another task collides with it.

### `test/spec/services/printer_service_spec.rb`

- Existing `tasks:` string doubles stay green because `print_tasks` still reads `day.tasks`.

### `test/e2e/e2e_spec.rb`

- Add a context that runs `run.rb` against `COLLISION_PATH` for DO 2020, parses the day block, and on `2020-01-01` asserts exactly one `Body(` occurrence, the merged `Ears` children `Drops_Apply` and `Camera_Wax_Remove` with `Drops_Apply` once, `Vitamins_Take` present, and `Zeta` present below `Body`.
- Confirm a day with no collisions in the existing `TEST_PATH` output is byte-identical to the current output. Choose a day with no collision deliberately; see the fixture note below.
- `test/test_config.yml` already produces merges on some days: `Tuesday_1` and `Tuesday_2` both render the leaf `Level_1` every Tuesday; `Thursday_1` renders the leaf `Level_1` while `Thursday_2` renders the internal `Level_1(...)` every Thursday; and `2020-01-31` receives two `Holiday` tags from `Last_Each_X_Day` and `Last_Day_January`. These outputs change under merge by design. Add explicit post-merge assertions for them (one `Level_1` on Tuesdays, `Level_1` internal with the leaf kept as a child on Thursdays, one merged `Holiday` on 2020-01-31) so the repository fixtures exercise the feature rather than hiding it.

### New Fixture `test/duplicate_tags_config.yml`

Create with `test/constants/test_constants.rb` gaining `COLLISION_PATH: './test/duplicate_tags_config.yml'`. Fixture content:

```yaml
lg_templates_config:
  base:
    - ""
    - "### Do"
    - ""
    - "```text"
    - "```"
task_templates_config:
  Body_Ears_Drops:
    Body:
      Ears:
        - Drops_Apply
  Body_Ears_Clean:
    Body:
      Ears:
        - Drops_Apply
        - Camera_Wax_Remove
  Body_Vitamins:
    Body:
      Vitamins_Take:
        - Pills
  Zeta_Template:
    - Zeta
tasks_config:
  Body_Ears_Drops_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Body_Ears_Drops
  Body_Ears_Drops_Task_2:
    method: to_specific_date
    month: 1
    day: 1
    template: Body_Ears_Drops
  Body_Ears_Clean_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Body_Ears_Clean
  Body_Vitamins_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Body_Vitamins
  Zeta_Task:
    method: to_specific_date
    month: 1
    day: 1
    template: Zeta_Template
```

Expected `2020-01-01` block:

```text
Body(
  Ears(
    Drops_Apply,
    Camera_Wax_Remove,
  ),
  Vitamins_Take(
    Pills,
  ),
),
Zeta,
```

## Summary Of Changes

- [ ] New `src/services/tag_merge_service.rb` with `roots_from_template`, `canonical_roots`, `add_roots`, `merge_nodes`, `merge_children`, and `render`.
- [ ] `TaskPrinterService#resolve_template` added and `print_from_template` refactored to use it.
- [ ] `ConfiguredTasksService` stores canonical roots under `config['tag']`.
- [ ] `AddTaskService` gains `attach` and drops the eight prepend sites in favor of it.
- [ ] `Day` gains `tag_roots`, initialized empty.
- [ ] `PrinterService` unchanged; `day.tasks` stays the rendered string.
- [ ] README TODO at `README.md:602` removed and merge behavior documented under Configuration.
- [ ] New `test/spec/services/tag_merge_service_spec.rb`, collision fixture, and e2e case.

## Verification Steps

Run these from the repository root. This spec does not run them; the implementer does.

```bash
bundle exec rspec
bundle exec rubocop
```

Then confirm the worked example manually by running DO mode against the collision fixture and diffing `2020-01-01` against the expected block above. The full suite must be green with 0 failures before this is called done.

## Open Questions

None. All decisions were resolved in the interactive rounds and confirmed by `docs/examples/DuplicateTags_Example.md`.
