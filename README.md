# Log Builder

## Contents

- [Overview](#overview)
- [Usage](#usage)
- [Sample Output](#sample-output)
- [Build Packaging](#build-packaging)
  - [Build Overview](#build-overview)
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
  Gear_Maintenance(
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

- This project is provisioned to leverage a fork of [Ruby Packer](https://github.com/ericbeland/ruby-packer) to compile an executable binary of the project.

### Download Requirements

- [Ruby Packer Release](https://github.com/ericbeland/ruby-packer/releases/tag/3_1_3)
- [Ruby Packer Dependencies](https://github.com/ericbeland/ruby-packer?tab=readme-ov-file#download)

### Complile from Source

- `$ ./build_package`

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
- [`to_each_xday`](#to_each_xday)
  - _Add to every Friday._
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

##### `to_each_xday`

```yaml
Friday_Project:
  method: to_each_xday
  day_name: Friday
  template: Code_Daily
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

## Version History

### 2024-05-01

- Resolves a bug preventing `to_nth_day_in_each_month` from functioning correctly the `nth_day` attribute.
  - Now treats `nth_day` and `day` attributes synonymously.

### 2024-04-11

- Logical retooling to read tasks from a YAML config file.
- 1st build compiled with Ruby Packer.

### 2025-01-26

- Implement config-drive LG mode.
- Deprecate hard-coded LG strings from the codebase.

## TODO Items

- [X] Address LG mode.
  - [X] Config driven.
  - [X] Add example to README.
- [ ] Warn of duplicate keys in YAML.
- [ ] Add begin/rescue blocks to all YAML-related methods.
  - [ ] Warn user of improper configuration.
  - [ ] Do not stop running on improper configuration.
- [ ] Validate inputs to `add_task_service`.
- [ ] Ask user to open with VIM.
- [ ] Calculate birthday age from year.

