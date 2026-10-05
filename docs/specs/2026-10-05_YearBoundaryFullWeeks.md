# Year Boundary Full Weeks

Branch context: no feature branch is created. This spec targets the repository default branch (`main`) of the `Log_Builder` Ruby CLI. It defines and corrects the day range that `Year` builds for a target year.

## Context And Motivation

`Year` expands a target year into the list of days every scheduling method walks (`src/models/year.rb:16`). The generator is meant to hand the rest of the tool complete Monday-start weeks that touch the target year, so a week straddling New Year is never cut in half.

The current generator hardcodes `54.times` and a start offset that is wrong when January 1 is a Monday (`src/models/year.rb:23`, `src/models/year.rb:30`). The result is an extra week in most years and a spurious prior-year December week in some of them. This was proven with a probe over 1990 to 2050 and against a generated `DO_2020.md`. The rule is real, it has never been specified or pinned by tests, and the logic does not implement it.

## Glossary

No `docs/GLOSSARY.md` change is required. The load-bearing terms are restated here so the spec stands alone.

- **Target year**: the integer passed to `Year.new` and stored as `year_number`, the calendar year the user asked for.
- **Boundary week**: a Monday-start, Sunday-end week that contains at least one day of the target year.
- **Range**: the contiguous block of days `Year#days` holds, from the first Monday to the last Sunday of the boundary weeks.
- **Offset**: the number of days from the Monday of the week containing January 1 to January 1 itself, so 0 for Monday, 1 for Tuesday, through 6 for Sunday.

## Current State

- `Year#initialize` runs `initialize_values`, then `54.times { add_next_week }`, then attaches configured tasks (`src/models/year.rb:23`).
- `Year::initialize_values` seeds the counters at prior-year December and maps the first Monday value into a December day with `@day_counter = 31 - (7 - @day_counter)` (`src/models/year.rb:30`).
- `Year#first_monday` computes `total_precession % 7` and returns `8 - that`, subtracting 7 when the result exceeds 7 (`src/models/year.rb:69`). When January 1 is a Monday the offset is 0, the value becomes 8, the clamp turns it into 1, and the start lands on December 25 of the prior year instead of January 1.
- `Year#add_next_week` pushes seven `Day` objects and rolls month and year over using `days_in_months` (`src/models/year.rb:41`). It is correct.
- `PrinterService#print_do_year` writes every entry in `do_year.days` with no year or month filter (`src/services/printer_service.rb:44`). `PrinterService#print_do_month` filters with `day.year == year && day.month == month` (`src/services/printer_service.rb:54`). Extra generated days therefore leak into the year file and are hidden in the month file.
- `test/spec/models/year_spec.rb:54` hardcodes the buggy output: first day December 2019, last day January 2021, `days.length == 378`.
- `test/spec/models/year_spec.rb:66` asserts the buggy January 1 2024 start lands on December 25 2023.
- Measured evidence: `ruby ./src/run.rb ./test/test_config.yml DO 2020 ALL /tmp/lb_probe` produced `DO_2020.md` with 378 day headers, including `## 2019-12-30`, `## 2019-12-31`, and `## 2021-01-01` through `## 2021-01-10`. The last three of those 2021 dates belong to no boundary week of 2020.
- Independent formula check over 1900 to 2100: the correct range is 53 weeks (371 days) in 194 years and 54 weeks (378 days) only in the seven leap years that begin on a Sunday: 1928, 1956, 1984, 2012, 2040, 2068, 2096.

## Goals

- Define the rule: `Year#days` holds exactly the days of the Monday-start weeks that intersect the target year.
- Start the range on January 1 when January 1 is a Monday, and on the prior-year December Monday otherwise.
- End the range on the Sunday on or after December 31, never later.
- Generate 53 weeks in a normal year and 54 weeks only in a leap year that begins on a Sunday.
- Pin the rule with unit tests over representative and adversarial years, plus a property test against `Date`.
- Prove the year-mode output contains no date before the range start and none after the range end.
- Keep `add_next_week`, `Day`, `PrinterService`, and every scheduling method unchanged.

## User Stories

1. As the log author, I want the year file to open on the Monday of the week that contains January 1, so that a New Year week is never split between two files.
2. As the log author, I want the year file to close on the Sunday of the week that contains December 31, so that the final week is complete.
3. As the log author, I want no days beyond those boundary weeks, so that the 2020 file never lists January 4 through January 10 of 2021.
4. As the log author, I want the 2024 file to start on January 1, not December 25 2023, so that a Monday New Year does not pull in the prior week.
5. As the log author, I want a leap year that begins on a Sunday to keep its 54-week range, so that the extra day does not truncate the final week.
6. As the maintainer, I want month mode behavior unchanged, so that `DO_<year>_<month>.md` still holds only the target month.
7. As the maintainer, I want the generation count derived rather than hardcoded, so that `54` never silently overruns again.
8. As the maintainer, I want a property test over two centuries, so that century and leap rules are proven rather than spot-checked.
9. As the maintainer, I want the year-mode output length asserted, so that a future range regression fails end to end.

## Non-Goals

- Changing `add_next_week`, `Day`, `PrinterService`, `AddTaskService`, or any scheduling method.
- Changing month mode or `print_do_month`.
- Adding a config option for the range.
- Changing which adjacent-year days a boundary week includes. Those days remain in range by design.
- Deduplicating tasks that match both the target year and an adjacent-year boundary day, such as a January 1 task appearing on January 1 of the following year. This is existing behavior and a separate concern.
- A `docs/GLOSSARY.md` change.

## Prerequisites

- Ruby 3.4.7 as pinned in `.tool-versions`.
- `bundle install` already run for the repository.
- No schema, database, service, or migration is involved. This is a single-process CLI.

## Design Principles

- Derive the range from two facts only: the offset of January 1 from its week Monday, and whether the target year is a leap year.
- Keep the existing Monday-anchored weekly loop and correct the seed and the count rather than rewriting generation.
- Keep every generated day inside a boundary week, so the invariant is checkable as a set equality.
- Prefer the existing integer arithmetic in `first_monday`; do not introduce a runtime `Date` dependency in `src/`.
- Keep the source diff to `src/models/year.rb`.

## Backend Requirements

### Offset Computation

Replace the clamped `first_monday` return with the raw offset in the range 0 through 6.

```ruby
def first_monday
  years_since = @year_number - 1
  leap_years = years_since / 4
  century_years = years_since / 100
  four_century_years = years_since / 400

  total_leap_years = leap_years - century_years + four_century_years
  total_precession = years_since + total_leap_years
  total_precession % 7
end
```

Behavior:

- Returns 0 when January 1 is a Monday, 1 for Tuesday, through 6 for Sunday.
- The value is exactly the number of days from the week Monday back to January 1.
- No clamping and no `8 -` inversion.

### Seed Computation

`initialize_values` seeds the counters from the offset.

- When the offset is 0, seed the target year, month 1, day 1.
- When the offset is greater than 0, seed prior year, month 12, day `32 - offset`.
- Remove the `31 - (7 - ...)` mapping and the unused `@day_counter` and `@week_counter` counters.

### Week Count Computation

Compute the number of weeks before the loop and iterate that many times instead of `54.times`.

```ruby
def initialize_values
  @days = []
  @days_in_months = get_days_in_months
  @day_offset = first_monday
  if @day_offset.zero?
    @year_counter = @year_number
    @month_counter = 1
    @day_in_month_counter = 1
  else
    @year_counter = @year_number - 1
    @month_counter = 12
    @day_in_month_counter = 32 - @day_offset
  end
end

def week_count
  days_in_year = leap_year? ? 366 : 365
  december_31_weekday = (@day_offset + days_in_year - 1) % 7
  trailing_days = (6 - december_31_weekday) % 7
  (@day_offset + days_in_year + trailing_days) / 7
end
```

Behavior:

- `week_count` equals `(range length) / 7`, the number of boundary weeks.
- Returns 53 in a normal year and 54 in a leap year that begins on a Sunday.
- The loop then runs `week_count.times { add_next_week }`.

### Unchanged Surfaces

- `add_next_week` and its month and year rollover are correct and stay as written, apart from deleting the unused incremented counter.
- `Day` (`src/models/day.rb`) is unchanged.
- `PrinterService` is unchanged.
- `AddTaskService` and `ConfiguredTasksService` are unchanged.
- No config key, constant, or error message is added or changed.

## Test Plan

Use the existing setup at `test/spec/models/year_spec.rb` with `TestConstants::CONFIG_FILES[:BLANK_PATH]`. Write the tests first, capture the red run against the current generator, then implement.

### Unit Cases In `test/spec/models/year_spec.rb`

- Range invariant for 2020, a normal year: first day `2019-12-30` and `Monday`, last day `2021-01-03` and `Sunday`, `days.length == 371`.
- Monday January 1, the proven start bug: 2024 first day is `2024-01-01`, no 2023 day is present, last day is `2025-01-05`, `days.length == 371`.
- Non-leap year ending exactly on a Sunday: 2023 runs `2022-12-26` through `2023-12-31` with no trailing day, `days.length == 371`.
- Leap year beginning on a Sunday, the only 54-week shape: 2012 runs `2011-12-26` through `2013-01-06`, `days.length == 378`, first `Monday`, last `Sunday`.
- Century rules: 1900 is not a leap year, 2000 is, 2100 is not; assert `leap_year?` directly and assert the 2000 range is a full 371 or 378 day multiple of seven with a Monday first day and Sunday last day.
- Year coverage: for 2020, every date from `2020-01-01` through `2020-12-31` appears exactly once, and the count of target-year days is 366.
- No overrun: for 2020, `2021-01-04` is absent; for 2024, `2023-12-31` is absent; for 2023, `2024-01-01` is absent.
- `week_count` is asserted indirectly through `days.length` and the first and last days.

### Property Test

Add one example that loops years 1900 through 2100, builds `Year.new(year, TestConstants::CONFIG_FILES[:BLANK_PATH])`, and compares against `Date`:

```ruby
require 'date'

(1900..2100).each do |year|
  do_year = Year.new(year, TestConstants::CONFIG_FILES[:BLANK_PATH])
  days = do_year.days
  jan1 = Date.new(year, 1, 1)
  dec31 = Date.new(year, 12, 31)
  expected_start = jan1 - ((jan1.wday - 1) % 7)
  expected_end = dec31 + ((7 - dec31.wday) % 7)

  expect(days.length % 7).to eq(0)
  expect(Date.new(days.first.year, days.first.month, days.first.month_day)).to eq(expected_start)
  expect(Date.new(days.last.year, days.last.month, days.last.month_day)).to eq(expected_end)
end
```

This is the load-bearing test. It fails today for every year whose January 1 is a Monday and for every year except the seven 54-week leap years.

### End-To-End Case In `test/e2e/e2e_spec.rb`

- In the existing full-year DO context, assert the parsed `@do_hash` holds exactly `371` dated entries for 2020.
- Assert `2019-12-30` and `2019-12-31` are present, and `2021-01-01`, `2021-01-02`, and `2021-01-03` are present.
- Assert `2021-01-04` is absent, which fails today and passes after the fix.

### Not Tested Here

- Month mode is already covered by `PrinterService#print_do_month` and its spec; it is unchanged.
- Scheduling methods are unchanged and keep their existing coverage.

## Summary Of Changes

- [ ] `src/models/year.rb` seeds the range from the true January 1 offset and loops `week_count` weeks instead of 54.
- [ ] `src/models/year.rb` no longer clamps the Monday offset and no longer uses the December mapping or the unused `@day_counter` and `@week_counter`.
- [ ] `test/spec/models/year_spec.rb` updates the 2020 and 2024 range assertions and adds the edge-year, coverage, no-overrun, and two-century property cases.
- [ ] `test/e2e/e2e_spec.rb` asserts the 2020 year file has 371 dated entries and no `2021-01-04`.
- [ ] No other `src/` file changes and no config file changes.

## Verification Steps

Run these from the repository root.

```bash
bundle exec rspec
bundle exec rubocop
ruby ./src/run.rb ./test/test_config.yml DO 2020 ALL /tmp/lb_check
grep -c '^## ' /tmp/lb_check/DO_2020.md
grep '^## 2021-01-04' /tmp/lb_check/DO_2020.md
```

Confirm the suite is green with 0 failures, rubocop reports 0 offenses, the header count prints `371`, and the `2021-01-04` grep prints nothing. Clean `/tmp/lb_check` afterward.

## Open Questions

None. The rule was stated by the maintainer: include the full Monday-start week before January 1 and the full Sunday-end week after December 31, and nothing beyond.
