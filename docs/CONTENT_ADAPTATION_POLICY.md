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

## Empty States

Empty background space does not automatically belong to a card. Empty-state
surfaces use local component constraints, bounded geometry, and content-driven
height rather than the full screen size.

- Desktop Effects and New Chests use the same section/header/surface family,
  but their height is determined by their own content. Empty collections use a
  compact centred message; populated collections wrap or grow in the page
  scroll view.
- A desktop first-quest message is centered in the remaining main workspace,
  but its landscape surface stays bounded (`<=720dp` wide) and content-led.
  It never inherits a portrait-shaped remaining-height card.
- Mobile Focus guidance has independent Full, Compact, Minimal, and Hidden
  variants derived from local sliver width/remaining height. The placeholder
  uses a quiet solid border because it is guidance, not a drag-and-drop target.
- A visually focused skill and Focus content always appear together; the
  overview never presents a fully selected skill card beside “Выбери навык для
  фокуса”.

This policy is currently implemented only for the surfaces above. Other empty
states require their own local audit before adopting the same rules.

## Unified Mobile RoadMap

Mobile RoadMap is one vertical, scroll-led bottom-up ascent graph. A local,
pure layout calculator uses available width and text scale to place the skill
root at the bottom, topology depths above it, and branch cards in non-overlapping
lanes. The mobile route does not reuse desktop free-pan canvas geometry or
mutate stored RoadMap order.
Circular nodes and adjacent descriptions follow source graph order
top-to-bottom; branch paths are selected from existing `RoadmapEngine` output
without changing graph data.

## Testing Matrix

Before accepting a typography/layout batch, verify at least:

- normal text scale and `200%` text scale for touched surfaces;
- `360/393/430/700dp` mobile where relevant;
- `900/1024/1180/1366/1440dp` desktop where relevant;
- dark and light theme usability;
- no `RenderFlex overflow` in widget tests.
