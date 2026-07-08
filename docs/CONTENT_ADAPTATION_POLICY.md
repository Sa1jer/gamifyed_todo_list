# Content Adaptation Policy

Last updated: 2026-07-08

## Principle

The app should adapt layout to real content instead of adapting content to a
fixed pixel box. Long Russian text, XP values, skill names, template names, and
accessibility text scaling must remain understandable without random font
shrinking.

## Approved Strategies

- Wrap titles to two or three lines when the component can grow.
- Reflow secondary metadata or XP rewards below the title on narrow surfaces.
- Let content-led cards grow inside a scrollable parent.
- Use `Flexible`, `Expanded`, `Wrap`, and responsive grid delegates before
  introducing special cases.
- Increase small visualizations such as weekly charts when text scale requires
  taller labels.
- Keep row hover/focus transitions geometry-stable: no size, padding, key, or
  border-width changes on pointer movement.

## Avoid

- String-length based font-size reduction.
- Hiding essential actions behind hover-only UI without keyboard/focus access.
- Fixed-height cards that contain multiple text lines.
- Nested scroll regions unless ownership is deliberate and tested.
- Layout fallback to old desktop compositions at intermediate widths.

## Desktop Notes

The new desktop shell owns the `>=761dp` range. Width pressure should adjust
sidebar/rail visibility and content density, not revive the old dashboard.

The sidebar skill list is the flexible scroll region. Brand, profile,
navigation, Inbox, and Settings remain anchored. Larger text may increase row
height, but row identity and reorder handles must stay stable.

## RoadMap Notes

Template selection uses runtime layout adaptation:

- narrow or large-text panels use one column;
- wider panels can use two columns;
- template titles use real names (`Простой`, `Нормальный`, `Сложный`,
  `Свой путь`) and may wrap rather than shrink.

Canvas node labels remain geometry-sensitive and are tracked as a follow-up in
the typography system.

## Testing Matrix

Before accepting a typography/layout batch, verify at least:

- normal text scale and `200%` text scale for touched surfaces;
- `360/393/430/700dp` mobile where relevant;
- `900/1024/1180/1366/1440dp` desktop where relevant;
- dark and light theme usability;
- no `RenderFlex overflow` in widget tests.
