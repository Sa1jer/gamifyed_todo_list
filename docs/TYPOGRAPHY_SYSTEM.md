# Typography System

Last updated: 2026-07-08

## Scope

`AppTypography` defines the shared semantic text scale for the app. It is a
presentation layer only: it does not change models, storage, XP, RoadMap data,
or task behavior.

The goal is to stop solving overflow by shrinking individual strings. Widgets
should use stable roles, then adapt layout through wrapping, reflow, spacing,
or scroll ownership.

## Theme Installation

`lib/main.dart` installs:

- `AppTypography.textTheme(colorScheme)` as the root `ThemeData.textTheme`;
- `AppTextRoles.fromTheme(...)` as a `ThemeExtension`.

`BuildContext.appTextRoles` also has a safe fallback. This is intentional:
some nested/local `Theme` widgets may replace `ThemeData` without copying
extensions. In that case roles are rebuilt from the active local `TextTheme`
and brightness instead of asserting at runtime.

## Semantic Roles

Use Material roles first:

- `headline*` for page or major panel titles;
- `title*` for cards, rows, and focused surfaces;
- `body*` for descriptions and explanatory copy;
- `label*` for buttons, metadata, chips, and compact controls.

Use `AppTextRoles` for product-specific cases:

- `reward`: XP/reward pills and reward values;
- `statValue`: larger numeric metrics;
- `numericRing`: ring or circular progress labels;
- `sectionEyebrow`: uppercase section labels;
- `compactMetadata`: dense skill/task metadata.

## Adaptation Policy

When text is too long or the user increases text scale:

- Prefer extra lines before shrinking text.
- Reflow reward/metadata into a second row when width is tight.
- Grow content-led cards inside scroll views.
- Increase chart or empty-state height when labels need it.
- Keep stable keys and geometry for hoverable rows.

Do not add per-string font-size heuristics such as "if length > 12, use 10px".
Only keep hardcoded font sizes when they are part of canvas geometry or icon
badges that require a fixed visual measurement; document those exceptions.

## Current Exceptions

The RoadMap painter still has a few geometry-linked labels whose size is tied
to node/canvas metrics. Those should be moved to explicit painter metrics in a
future RoadMap token pass rather than mixed into product text roles.

## Tests

Coverage added in `test/app_typography_test.dart` verifies:

- the semantic scale values;
- product text-role generation;
- nested `ThemeData` without extensions no longer crashes.

Widget coverage verifies long focus titles, large text scale, RoadMap template
titles, sidebar action geometry, and weekly chart height.
