# Glossary

Project-specific domain terms. Each entry defines what the concept is, not what it does.

**Tag**

A single rendered node produced by a configured task, for example `Body(...)` or `Git,`. _Avoid_: label, marker, entry.

**Root Tag**

A tag at the top level of a day's task list, not nested inside another tag. _Avoid_: top tag, parent tag.

**Internal Node**

A tag that has children and renders with parentheses, for example `Groom(...)`. _Avoid_: container, branch.

**Leaf Node**

A tag with no children that renders as text followed by a comma, for example `Git,`. _Avoid_: terminal, scalar.

**Configured Task**

An entry under `tasks_config` that a scheduling method attaches to one or more days. _Avoid_: job, rule.

**Canonical Tag Node**

The merge-time representation shared by all tags, expressed as `{ name:, leaf:, children: }`. _Avoid_: AST, model, tree node.

**Tag Tree**

The nested structure a task printer consumes and renders, made of hashes and arrays. _Avoid_: AST, document model.

**Tag Order**

The configured sequence in `tag_order_config` that fixes the position of root tags within a day: a listed tag takes its list position, and the `~~OTHER~~` marker gives the position of every tag not named in the list. _Avoid_: tag weight, priority, rank.

**Build Year**

The integer supplied on the command line and stored as `Year#year_number`, against which birthday age is calculated. _Avoid_: run year, target year.

**Birth Year**

The optional `birth_year` integer on a `to_specific_date` task recording the calendar year a person was born. _Avoid_: year, birthdate, dob.

**Age**

The Build Year minus the Birth Year, rendered as a base-10 integer string into a task's `{{AGE}}` placeholder. _Avoid_: completed age, exact age.
