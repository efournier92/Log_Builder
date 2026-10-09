# Log Builder

## Contents

- [Overview](#overview)
- [Usage](#usage)
- [Sample Output](#sample-output)
- [Build Packaging](#build-packaging)
  - [Build Overview](#build-overview)
  - [Runtime Requirements](#runtime-requirements)
  - [Running and Installing](#running-and-installing)
- [Configuration](#configuration)
  - [Configuration Overview](#configuration-overview)
  - [Templates](#templates)
    - [Template Structure](#template-structure)
    - [Template Examples](#template-examples)
  - [Tasks](#tasks)
    - [Task Structure](#task-structure)
    - [Supported Methods](#supported-methods)
    - [Task Examples](#examples)
    - [Holidays](#holidays)
    - [Birthdays](#birthdays)
  - [Same-Day Tag Merging](#same-day-tag-merging)
  - [Tag Order](#tag-order)
- [Version History](#version-history)
- [TODO Items](#todo-items)

## Overview

- **Facilitates capturing prospective and retrospective data from your day in a handy Markdown syntax.**
- *Builds a daily prospective TODO-style list structure with tasks fed from a configuration file.*
- *Allows you to capture retrospective points of reference from each day of your life.*

## Usage

```bash
$ log-builder $CONFIG_FILE [$MODE] [$YEAR] [$MONTH] [$OUTPUT_DIR]
```

## Sample Output

````markdown
## 2020-01-01 | Wednesday

```text
Holiday(
  New_Years_Day,
),
Birthday(
  Name(YourFriend,),
  Contact(your_friend@example.com,),
),
Home_Admin(
  Utility(
    Amount(),
  ),
):
Code_Project_Work(
  Readme_Finish,
  Git_Commit,
),
Event_Attend(
  @(
    Arrive(),
    Depart(),
  ),
  Location(
    Name(),
    Address(),
  ),
  Because(
    TODO,
  ),
  Strategy(
    TODO,
  ),
  Result(
    TODO,
  ),
),
Hobby_Gear(
  Version_Adjust(
    Because(
      Months_Since(3,),
    ),
    Strategy(
      Type(Brand_Name,),
    ),
    Result(
      TODO,
    ),
  ),
),
```
````

## Build Packaging

### Build Overview

- `ruby build.rb` produces `builds/log-builder_YYYY-MM-DD`, a single self-contained Ruby file containing all of Log Builder's runtime logic.
- The generated file is never to be edited by hand.
  - **Run `ruby build.rb` to regenerate it.**
- You'll find multiple snapshots in `builds/`.
  - Favor the newest file.
- After changing `src/`, run `ruby build.rb` and commit the new dated file in `builds/` in the same commit.
  - The `build_spec` drift test and CI fail until the committed snapshot matches `src/`.
- After adding any file under `src/`, add its path to `SOURCE_ORDER` in `build.rb` (`src/run.rb` stays last).
  - A test fails until you do, and the file is otherwise silently left out of the Bundle.

### Runtime Requirements

- The generated file runs on any Ruby 2.6+ version.
  - Only requires `yaml` and `fileutils` standard libraries.
  - The floor is not covered by CI; after each build, verify with `ruby -c builds/log-builder_*` on a 2.6 interpreter.
- Config parsing uses [Psych](https://github.com/ruby/psych).
  - A config with YAML aliases or anchors loads on Ruby 2.6 (Psych 3) but raises `Psych::AliasesNotEnabled` on Ruby 3.1 and newer.
  - Avoid aliases for cross-version portability.
- Rebuilding from source requires Ruby 3.3 or newer so `prism` is available.
  - The dev Ruby is pinned in `.tool-versions` (`asdf` or `mise`); CI runs Ruby 3.4.

### Running and Installing

- See `test/test_config.yml` for a sample config file.
- Run a build directly, no install needed.
  - Example: `ruby builds/log-builder_YYYY-MM-DD YOUR_CONFIG.yml`
- Install the newest build as a stable `log-builder` command.
  - `./bin/install ~/.local/bin` installs it as `~/.local/bin/log-builder`.
    - `~/.local/bin` is (YOUR PREFERRED INSTALL DIRECTORY); substitute any directory on your `PATH`.
  - System directories such as `/usr/local/bin` need `sudo`.
    - Example: `sudo ./bin/install /usr/local/bin`
  - Add the install directory to your `PATH` if it is not already there.
    - zsh: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`
    - bash: `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc`
  - Re-run `./bin/install` to update; it overwrites `log-builder` in place.
  - The dated files stay in `builds/`, so install an older one to roll back.
  - The script picks the newest by filename; remove a stray dated file if one appears.

## Configuration

### Configuration Overview

- Logs are built based on a `yml` configuration file.
  - This file's location is to be fed as the 1st argument in the CLI command at runtime.
    - `log-builder ./log_builder_config.yml`
  - This file supports configuration of templates and tasks.
    - Examples are detailed below.
- Configured templates support placeholder values.
  - Denoted by `{{ }}` syntax.
  - Values to populate can be supplied from configured tasks.
    - Via the `template_variables` configuration property.
  - A template can inline another named template by using `'{{Template_Name}}':` as a key where that template's contents should appear.

### Templates

#### Template Structure

```yaml
task_templates_config:
  $TEMPLATE_NAME:
    $TASK:
      - $TASK_DETAIL
```

#### Template Examples

##### Lg

```yaml
lg_templates_config:
  base:
    - ""
    - "### Do"
    - ""
    - "```text"
    - "```"
    - ""
  weekday:
    - "### Notes"
    - ""
    - "#### Yesterday"
    - ""
    - "#### Today"
    - ""
  monday:
    - "### Notes"
    - ""
    - "#### Last Friday"
    - ""
    - "#### Today"
    - ""
  friday:
    - "### Notes"
    - ""
    - "#### Yesterday"
    - ""
    - "#### Today"
    - ""
    - "### Review"
    - ""
    - "#### Last Friday"
    - ""
    - "#### Today"
    - ""
```

##### Do

```yaml
Holiday:
  Holiday:
    - '{{NAME}}'
Birthday:
  Birthday:
    - 'Name({{NAME}},)'
    - 'Contact({{CONTACT}},)'
Code_Daily:
  Code_Project_Work:
    - Readme_Finish
    - Git_Commit
Event_Attend:
  Event_Attend:
    '@':
      Arrive(TODO,):
      Depart(TODO,):
    Location:
      Name():
      Address():
    Because:
      - TODO
    Strategy:
      - TODO
    Result:
      - TODO
```

### Tasks

#### Task Structure

##### From Template Name

```yaml
tasks_config:
  $TASK_NAME:
    method: $METHOD_NAME
    $DATE_CONFIG: $DATE_CONFIG
    template: $TEMPLATE_NAME
```

##### From Inline Template

```yaml
tasks_config:
  $TASK_NAME:
    method: $METHOD_NAME
    $DATE_CONFIG: $DATE_CONFIG
    template:
      $TEMPLATE_NAME:
        $TEMPLATE_NODE:
          - $TEMPLATE_DETAIL
```

#### Supported Methods

- [`to_specific_date`](#to_specific_date)
  - _Add to January 15th._
- [`to_each_day`](#to_each_day)
  - _Add to every day._
- [`to_each_xday`](#to_each_xday)
  - _Add to every Friday._
- [`to_each_weekday`](#to_each_weekday)
  - _Add to every weekday (Monday through Friday)._
- [`to_each_weekend`](#to_each_weekend)
  - _Add to every weekend day (Saturday and Sunday)._
- [`to_nth_xday_in_month`](#to_nth_xday_in_month)
  - _Add to the 2nd Friday in a specific month._
- [`to_nth_xday_in_each_month`](#to_nth_xday_in_each_month)
  - _Add to the 2nd Friday in every month._
- [`to_last_xday_in_month`](#to_last_xday_in_month)
  - _Add to the last Friday in a specific month._
- [`to_last_xday_in_each_month`](#to_last_xday_in_each_month)
  - _Add to the last Friday in every month._
- [`to_last_day_in_month`](#to_last_day_in_month)
  - _Add to the last day in a specific month._
- [`to_last_day_in_each_month`](#to_last_day_in_each_month)
  - _Add to the last day in every month._
- [`to_nth_day_in_each_month`](#to_nth_day_in_each_month)
  - _Add to the 15th day of each month._
- [`to_nth_day_in_each_quarter`](#to_nth_day_in_each_quarter)
  - _Add to the 1st day of each quarter._
- [`to_xday_every_n_weeks`](#to_xday_every_n_weeks)
  - _Add to every 3rd Friday._
- [`to_easter`](#to_easter)
  - _Add to Easter Sunday._
- [`to_good_friday`](#to_good_friday)
  - _Add to the Friday before Easter Sunday._

#### Examples

##### `to_specific_date`

```yaml
Christmas:
  method: to_specific_date
  month: 12
  day: 25
  template: Holiday
  template_variables:
    - '{{NAME}}': Christmas
```

##### `to_each_day`

```yaml
Daily_Journal:
  method: to_each_day
  template: Code_Daily
```

`day_name` is not accepted; the method attaches to every day, and supplying a `day_name` (valid or not) raises an `INVALID_DAY_NAME` error.

##### `to_each_xday`

```yaml
Friday_Project:
  method: to_each_xday
  day_name: Friday
  template: Code_Daily
```

##### `to_each_weekday`

```yaml
Weekday_Standup:
  method: to_each_weekday
  template: Code_Daily
```

##### `to_each_weekend`

```yaml
Weekend_Review:
  method: to_each_weekend
  template: Weekly_Review
```

##### `to_nth_xday_in_month`

```yaml
Presidents_Day:
  method: to_nth_xday_in_month
  month: 2
  nth_day: 3
  day_name: Monday
  template: Holiday
  template_variables:
    - '{{NAME}}': Presidents_Day
```

##### `to_nth_xday_in_each_month`

###### Every Month

```yaml
Event_Monthly_Attend:
  method: to_nth_xday_in_each_month
  nth_day: 3
  odd_only: true
  day_name: Saturday
  template: Event_Attend
```

###### Every Odd Month

```yaml
Event_Monthly_Attend:
  method: to_nth_xday_in_each_month
  nth_day: 3
  odd_only: true
  day_name: Saturday
  template: Event_Attend
```

###### Every Even Month

```yaml
Event_Monthly_Attend:
  method: to_nth_xday_in_each_month
  nth_day: 3
  even_only: true
  day_name: Saturday
  template: Event_Attend
```

##### `to_last_xday_in_month`

```yaml
Memorial_Day:
  method: to_last_xday_in_month
  month: 5
  day_name: Monday
  template: Holiday
  template_variables:
    - '{{NAME}}': Memorial_Day
```

##### `to_last_xday_in_each_month`

```yaml
Bill_Pay:
  method: to_last_xday_in_each_month
  day_name: Friday
  template:
    Home_Admin:
      Utility:
        - Amount(TODO,)
```

##### `to_last_day_in_month`

```yaml
Log_NextYear:
  method: to_last_day_in_month
  month: 12
  template:
    - Log_NextYear
```

##### `to_last_day_in_each_month`

```yaml
Log_NextMonth:
  method: to_last_day_in_each_month
  template:
    - Log_NextMonth
```

##### `to_nth_day_in_each_month`

```yaml
Log_LastMonth:
  method: to_nth_day_in_each_month
  nth_day: 1
  template:
    - Log_LastMonth
```

##### `to_nth_day_in_each_quarter`

```yaml
Gear_Maintenance:
  method: to_nth_day_in_each_quarter
  nth_day: 1
  template:
    - Gear_Maintenance
```

##### `to_xday_every_n_weeks`

```yaml
Event_Biweekly_Attend:
  method: to_xday_every_n_weeks
  day_name: Friday
  n_weeks: 2
  template: Event_Attend
```

##### `to_easter`

```yaml
Easter:
  method: to_easter
  template: Holiday
  template_variables:
    - '{{NAME}}': Easter
```

##### `to_good_friday`

```yaml
Good_Friday:
  method: to_good_friday
  template: Holiday
  template_variables:
    - '{{NAME}}': Good_Friday
```

#### Holidays

```yaml
tasks_config:
  New_Years_Day:
    method: to_specific_date
    month: 1
    day: 1
    template: Holiday
    template_variables:
      - '{{NAME}}': New_Years_Day
  Presidents_Day:
    method: to_nth_xday_in_month
    month: 2
    nth_day: 3
    day_name: Monday
    template: Holiday
    template_variables:
      - '{{NAME}}': Presidents_Day
  Valentines_Day:
    method: to_specific_date
    month: 2
    day: 14
    template: Holiday
    template_variables:
      - '{{NAME}}': Valentines_Day
  DaylightSavings_Begins:
    method: to_nth_xday_in_month
    month: 3
    nth_day: 2
    day_name: Sunday
    template: Time_Change
    template_variables:
      - '{{DESCRIPTION}}': DaylightSavings_Begins
  Good_Friday:
    method: to_good_friday
    template: Holiday
    template_variables:
      - '{{NAME}}': Good_Friday
  Easter:
    method: to_easter
    template: Holiday
    template_variables:
      - '{{NAME}}': Easter
  Mothers_Day:
    method: to_nth_xday_in_month
    month: 5
    nth_day: 2
    day_name: Sunday
    template: Holiday
    template_variables:
      - '{{NAME}}': Mothers_Day
  Memorial_Day:
    method: to_last_xday_in_month
    month: 5
    day_name: Monday
    template: Holiday
    template_variables:
      - '{{NAME}}': Memorial_Day
  Fathers_Day:
    method: to_nth_xday_in_month
    month: 6
    nth_day: 3
    day_name: Sunday
    template: Holiday
    template_variables:
      - '{{NAME}}': Fathers_Day
  Juneteenth:
    method: to_specific_date
    month: 6
    day: 19
    template: Holiday
    template_variables:
      - '{{NAME}}': Juneteenth
  Independence_Day:
    method: to_specific_date
    month: 7
    day: 4
    template: Holiday
    template_variables:
      - '{{NAME}}': Independence_Day
  Labor_Day:
    method: to_nth_xday_in_month
    month: 9
    nth_day: 2
    day_name: Tuesday
    template: Holiday
    template_variables:
      - '{{NAME}}': Labor_Day
  Halloween:
    method: to_specific_date
    month: 10
    day: 31
    template: Holiday
    template_variables:
      - '{{NAME}}': Halloween
  DaylightSavings_Ends:
    method: to_nth_xday_in_month
    month: 11
    nth_day: 1
    day_name: Sunday
    template: Time_Change
    template_variables:
      - '{{DESCRIPTION}}': DaylightSavings_Ends
  Veterans_Day:
    method: to_specific_date
    month: 11
    day: 11
    template: Holiday
    template_variables:
      - '{{NAME}}': Veterans_Day
  Thanksgiving:
    method: to_nth_xday_in_month
    month: 11
    day: 4
    day_name: Thursday
    template: Holiday
    template_variables:
      - '{{NAME}}': Thanksgiving
  Christmas_Eve:
    method: to_specific_date
    month: 12
    day: 24
    template: Holiday
    template_variables:
      - '{{NAME}}': Christmas_Eve
  Christmas:
    method: to_specific_date
    month: 12
    day: 25
    template: Holiday
    template_variables:
      - '{{NAME}}': Christmas
  NewYears_Eve:
    method: to_specific_date
    month: 12
    day: 31
    template: Holiday
    template_variables:
      - '{{NAME}}': NewYears_Eve
```

### Same-Day Tag Merging

When two configured tasks render a root tag with the same name on the same day, the tags merge into one root. Merging is always on and silent.

- Merging is recursive: same-named internal nodes merge at each level, and identical leaves collapse.
- Incoming children are placed before existing children at each merged level.
- The merged root stays in the slot of its lowest occurrence, so tags below it do not move.
- Tags that do not collide render exactly as before.
- When an internal tag and a leaf tag share a name, the internal tag is kept and the leaf becomes its first child.

For example, four `Body` contributions on one day collapse into a single `Body`:

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
```

### Tag Order

Root tags render in the order of the optional top-level `tag_order_config` list, top entry first. Without the key, root tags render in the order they attach.

- Tag order applies to root tags only, and it runs after same-day merging, so a merged root takes its ordered slot.
- List the root tag names in the order you want them, first to last.
- Use the reserved `'~~OTHER~~'` entry to position every tag not named in the list. Quote it in YAML.
- Without `'~~OTHER~~'`, unlisted tags render after all listed tags.
- Tags that share a position keep their existing relative order.
- Omit the key, or leave it empty, to render exactly as before.
- A configured root tag named `~~OTHER~~` is reserved and raises an `INVALID_CONFIG` error, even when `tag_order_config` is absent.

```yaml
tag_order_config:
  - Holiday
  - Birthday
  - Career
  - '~~OTHER~~'
  - Body
```

In the example, `Holiday`, `Birthday`, and `Career` render first in that order, every unlisted tag renders next, and `Body` renders last.

### Birthdays

```yaml
Birthday_AbeLincoln:
  method: to_specific_date
  month: 2
  day: 12
  template: Birthday
  template_variables:
    - '{{NAME}}': AbeLincoln
    - '{{CONTACT}}': honest_abe_1809@hotmail.com
```

Add the optional `birth_year` key to print the person's age against the build year. Define a dedicated template that appends the age through `{{AGE}}`:

```yaml
Birthday_With_Age:
  Birthday:
    - 'Name({{NAME}},)'
    - 'Contact({{CONTACT}},)'
    - 'Age({{AGE}},)'
```

```yaml
Birthday_AbeLincoln_Age:
  method: to_specific_date
  month: 2
  day: 12
  birth_year: 1809
  template: Birthday_With_Age
  template_variables:
    - '{{NAME}}': AbeLincoln
    - '{{CONTACT}}': honest_abe_1809@hotmail.com
```

The age is the build year minus `birth_year`, rendered as a plain integer. When `birth_year` is set, the template must reference `{{AGE}}` or the task raises an `INVALID_CONFIG` error.

## Version History

### 2026-10-08

- Validates the configuration once at load: one pass collects every problem, prints one report to STDERR, and exits non-zero before any output file is written.
  - Catches YAML syntax errors, duplicate keys, unknown or missing methods, missing or mistyped keys, unknown top-level keys, and unresolved templates or placeholders.
  - Reports the config path and 1-based line numbers, and names the owning task for a render error.
  - Rejects a null, Integer, or otherwise non-String, non-mapping, non-list `template` instead of silently attaching nothing.
  - Requires every `lg_templates_config` value to match the `base` type, String or list, so a mixed config cannot raise a raw `TypeError` during LG rendering.
- Writes output through a sibling temp file and renames it into place, so a failed render leaves any existing file untouched.
- Echoes `Wrote File > <path>` to STDOUT on each successful write (for example `Wrote File > ./DO_2026_01.md`).
- Expands a `{{Template_Name}}` key that inlines another template even when every sibling is a leaf, instead of writing the raw placeholder into the log.

### 2026-10-05

- Adds an optional `birth_year` to `to_specific_date` tasks, rendered through the `{{AGE}}` placeholder as the build year minus the birth year.
  - A `birth_year` on another method, a non-integer or future value, or a template without `{{AGE}}` raises an `INVALID_CONFIG` error.
- Corrects full-year generation to include exactly the complete Monday-start weeks that intersect the target year.
  - A normal year file now has 371 dated entries instead of 378, and a year beginning on a Monday no longer starts in the prior December; a leap year beginning on Sunday keeps 54 weeks.
- Replaces the Ruby Packer binary build with a single self-contained Ruby file, `builds/log-builder_YYYY-MM-DD`, generated by `ruby build.rb`, and retires the `build_package` script and its toolchain.
  - The target machine now needs a Ruby 2.6 or newer interpreter; the retired native binary needed none, but it was platform-locked.

### 2026-10-04

- Adds `to_each_weekday` and `to_each_weekend` scheduling methods.
  - `to_each_weekday` attaches a task to every Monday through Friday.
  - `to_each_weekend` attaches a task to every Saturday and Sunday.
  - Both ignore `odd_only` and `even_only`, and reject a supplied `day_name`.
- Adds optional `tag_order_config` root tag ordering, applied after same-day merging, with the reserved `~~OTHER~~` marker for unlisted tags, and a raise when a configured tag uses the reserved marker name.
- Changes `to_each_day` to reject a supplied `day_name` (valid or not), matching `to_each_weekday` and `to_each_weekend`.

### 2025-01-26

- Implement config-drive LG mode.
- Deprecate hard-coded LG strings from the codebase.

### 2024-05-01

- Resolves a bug preventing `to_nth_day_in_each_month` from functioning correctly the `nth_day` attribute.
  - Now treats `nth_day` and `day` attributes synonymously.

### 2024-04-11

- Logical retooling to read tasks from a YAML config file.
- 1st build compiled with Ruby Packer.

## TODO Items

- [X] Address LG mode.
  - [X] Config driven.
  - [X] Add example to README.
- [X] Calculate birthday age from year.
- [X] Echo the written output path on success, so the user can open it in their editor.

