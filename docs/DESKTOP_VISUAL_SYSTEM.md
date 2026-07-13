# Desktop Visual System

Last updated: 2026-07-13

## Scope

The desktop presentation uses a dedicated adaptive shell at widths of `761dp`
and above. The existing mobile composition remains active through `760dp`.
This layer is presentation-only: it reuses `AppState`,
models, dialogs, RoadMap, task mutations, XP rules, history, and storage without
changing their contracts.

The reference-led layout is:

- a compact, full-height skill and navigation sidebar;
- a dominant action workspace with real daily metrics and dense quest rows;
- a narrow contextual rail with focus, weekly activity, and skill XP.

Native platform window chrome is preserved. The project has no safe custom
window-management integration, so the UI does not draw fake macOS controls or
replace Windows controls.

## Responsive Boundary

`DesktopResponsiveMetrics` centralizes four tiers:

- `761-1023`: `232dp` sidebar, dominant center, right rail collapsed;
- `1024-1279`: `232dp` sidebar, `236dp` rail, compact center padding;
- `1280-1599`: `248dp` sidebar, `260dp` rail;
- `1600+`: `264dp` sidebar, `288dp` rail and controlled extra padding.

The RoadMap keeps the sidebar but uses the full remaining workspace and hides
the contextual rail. No width can select the legacy desktop dashboard: compact
mobile and new desktop are the only shell families.

The sidebar owns one flexible scrolling skill list. Brand, profile and primary
navigation stay stable above it; Inbox and the compact Settings footer remain
anchored below it. Skill rows are `62dp` high, while the wider sidebar preserves
name, metadata and progress hierarchy.

## Tokens

`DesktopJournalTokens` owns the local dark and light surface hierarchy, text,
outline, profile, reward, success, active, streak, and danger colors. Skill
colors remain dynamic and local to the selected skill. Reward XP remains gold
and never inherits the skill color.

The new desktop layer does not migrate global `ThemeData` and does not alter
the mobile journal tokens.

## Data Sources

- Character and skill bars use current-level `xp / xpNeeded`.
- Completed and XP-today cards use `AppState.todayStats`.
- Active count uses non-completed skill tasks.
- Streak uses the highest real streak among current repeating tasks.
- The focus set is the union of skill tasks completed today and current active
  skill tasks. Its denominator safely remains zero when no tasks exist.
- Weekly activity uses effective completion entries from
  `AppState.completionHistoryByDate`, Monday through Sunday.
- XP by skill uses each skill's current-level `Skill.xp`.
- Type badges map the existing `TaskType` values to `Привычка`, `Разово`,
  `Проект`, and `Большая цель`.

No placeholder statistics or synthetic chart values are shown.

## Interaction And Accessibility

Sidebar navigation, skills, Inbox, quest rows, and rail tasks have pointer
cursors and restrained surface transitions. Existing profile, tutorial replay,
debug mark, statistics, trophies, skill editing/deletion, task editing/deletion,
completion/undo, minimum action, reorder, and RoadMap entry points remain wired.

Selected navigation and skill rows expose selected semantics. Quest rows expose
state and XP reward, focus exposes `completed / total` and percentage, and the
weekly chart exposes a textual seven-day summary. Color is accompanied by
icons, labels, checks, or text values.

Animations are implicit and short. Platform reduced-motion disables the main
skill-content swap. No continuously running controller, blur, shader, or
particle layer was added.

Right-rail focus rows own local hover/focus state keyed by stable task ID. Hover
changes only tint and border color over `110ms`; padding, border width and row
height remain fixed, so pointer movement cannot restart layout or flash rows.

## Inbox And Quest Creation

Desktop Inbox uses the normal workspace canvas rather than one full-height
bordered card. Its header, composer, active section and completed section size
to their content. Green is limited to Inbox identity and completion context;
XP remains reward gold and task rows use neutral raised surfaces.

Quest creation shares one form anatomy on mobile and desktop while preserving
platform composition. The order is `Название квеста`, `Описание`, `XP за
квест`, then `Настройки квеста`. Description is a bounded multiline field,
Minimum Step lives inside Settings, and SMARTER creation/edit controls are
frozen pending a product decision. The XP selector uses `10`-point increments
through `500`; legacy non-grid rewards remain unchanged until the user edits
the XP control.

## Intentional Differences From The Reference

- Native window chrome is retained instead of drawing simulated traffic-light
  controls.
- Weekly bars and focus values use available production data, so empty accounts
  correctly show zero activity.
- The system Inbox remains available as a compact sidebar shortcut to preserve
  existing desktop functionality.
- RoadMap keeps its approved canvas painter and graph visuals while its shell
  participates in the persistent desktop workspace. Trophies and Statistics
  now open as first-class shell pages; their mobile/tutorial dialogs remain
  available where modal focus is intentional.

## Desktop Secondary Workspaces

`WorkspaceMode` now covers Act, RoadMap, Trophies, Statistics, and Settings.
Desktop navigation changes the center workspace instead of opening legacy
windows. Statistics uses a dedicated shell-native overview and eight
in-workspace detail pages while reusing existing history, goal, resistance,
achievement, and course-nudge data. Trophies combines real progress, effects,
chests, and earning rules. Settings groups every existing profile/interface/
local-data preference and keeps the richer profile editor as a secondary
action.

RoadMap selection stays synchronized with the sidebar skill ID. Camera
centering fits measured content bounds into the actual target viewport without
changing canvas paint, node geometry, graph ordering, or persistence. The
desktop toolbar controls layout, templates, centering, and expansion; the
context rail and template cards use the selected skill accent.

The first fit is applied synchronously once layout bounds are known, so a
newly opened RoadMap does not briefly paint at the identity transform and then
jump. During native window resizing, fitting remains debounced to avoid
restarting the camera animation on every intermediate constraint. Reduced
motion applies the resulting transform without a camera animation.

Skill and quest context actions use stable vertical-ellipsis hit regions that
fade on hover/focus without changing row geometry. Reordering remains on the
existing delayed-drag gesture. A skill that has never contained a quest shows
one compact first-quest explanation and relies on the header CTA, avoiding a
second competing action.

## 1.3.52 Recovery

The `1.3.52` commit established routes and wrappers but left several target
flows as old content inside a new shell. `1.3.53` replaces those partial paths:

- RoadMap now owns a compact toolbar, contextual rail, migrated templates, and
  bounds-based camera fit while preserving the approved canvas renderer.
- Trophies now exposes real in-progress, effects, chest, and earning sections.
- Statistics no longer embeds `ProgressHubContent`; all eight primary detail
  entries remain inside the desktop shell.
- Settings exposes the full existing preference surface and local persistence
  status without inventing controls.
- Selected skills use a responsive raised header, history-aware empty state,
  stable action slots, and top-left aligned transitions.
- Admin entry uses a stable four-second five-tap window in debug/profile builds;
  release builds retain runtime guards at the entry, controller, and storage.

The complete audit and evidence matrix is in
`docs/1.3.52_RECOVERY_AUDIT.md`.

## Follow-up Validation

- Compare pointer and scaling behavior on physical Windows QHD at 125% and 150%.
- Compare native macOS density at 1440, 1920, and 2560 widths.
- Profile rebuild boundaries with very large skill/task histories if real data
  shows frame pressure.
- Revisit minor visual spacing only after side-by-side native screenshots; do
  not alter domain behavior during that polish.

## 1.3.54 Stability Boundary

The architecture audit removed the unreachable legacy `TopBar` branch that
could no longer be selected by the centralized desktop breakpoint resolver.
The live mobile bottom navigation was extracted and retained. Desktop and
mobile therefore keep their approved compositions without carrying an unused
596-line legacy header implementation.

Flutter `3.44.3` is now the minimum project SDK because reorderable skill lists
use `ReorderableListView.onReorderItem`. This prevents older Windows analyzer
instances from reporting source errors against a newer framework API.

## 1.3.55 Typography And Adaptive Content

The desktop shell now uses the shared `AppTypography` / `AppTextRoles`
foundation for new and migrated surfaces. The rule is to keep semantic text
sizes stable and adapt layout instead of shrinking strings ad hoc.

The practical desktop fixes in this boundary are:

- nested or local `ThemeData` can no longer crash when `AppTextRoles` is absent;
- RoadMap canvas selection now updates the sidebar selected skill, and sidebar
  selection still updates the canvas without loops;
- right-rail focus rows reflow long titles and XP at large text scale;
- weekly activity grows vertically for large text labels;
- skill rows reveal action menus on hover/focus without a permanent drag glyph;
- RoadMap template cards wrap stable titles and switch to one column in narrow
  or large-text panels.

Detailed rules live in `docs/TYPOGRAPHY_SYSTEM.md` and
`docs/CONTENT_ADAPTATION_POLICY.md`.

## 1.3.56 Responsive Stabilization

RoadMap camera fitting is debounced while native window constraints are moving.
This prevents every intermediate `LayoutBuilder` pass from restarting the
`TransformationController` animation, while preserving manual centering and
the final fit after resize settles.

Desktop empty states are content-led: an unused RoadMap chooses compact,
normal, or large overlay metrics from actual canvas constraints; a fresh skill
uses the remaining main-workspace height for its first-quest guidance and
falls back to scrolling only at short window heights. Effects and unopened
chests share one natural-height collection anatomy. Secondary shell navigation
returns to the last normal workspace when its active item is selected again.

## 1.3.58 Desktop RoadMap Freeze Contract

The unified mobile RoadMap is presentation-only and does not reuse the desktop
InteractiveViewer route. Desktop canvas, toolbar, context rail, template panel,
selection synchronization, camera fit, and graph order remain unchanged.

## 1.3.59 Desktop RoadMap Freeze Contract

`MobileRoadMapAscentLayout` is imported only by the mobile RoadMap journal.
It projects existing snapshots into a mobile-only ascent: the skill root stays
at the top, while foundations and prerequisite links rise toward it. It does
not participate in desktop canvas geometry, camera fitting, toolbar controls,
template application, or selection synchronization.

## 1.3.60 Selected-Skill Header Geometry

The active selected-skill header is content-led rather than offset-led. Its
single desktop row has a stable emblem slot, a three-row content column, and a
stable primary-action slot. The content column keeps the skill name, level,
and real non-empty goal in its identity row; its XP track/value in the second
row; and the approved plain-text `Всего квестов: N` value in the third row.

The emblem and primary action centre against the complete content column, not
against only the XP row. At constrained desktop widths or large text the goal
can move below the identity row and the action can take a controlled second
row. The component never invents a goal, turns the total into a chip, counts
Inbox tasks, or falls back to the legacy selected-skill header.

Static macOS hang investigation covered recent layout, RoadMap, listener,
timer, animation, and `LayoutBuilder` paths. No deterministic UI-isolate loop
was proven, so this release adds no speculative lifecycle workaround. Native
profile capture during an actual stall remains the required next evidence.

## 1.3.57 Content-Driven Empty-State Recovery

The Trophies Effects and New Chests sections now share the same full-width
section anatomy without matching fixed heights. Empty collections contain a
centred, bounded content surface; populated chests switch to a local two-column
wrap only when their own content width permits it.

The fresh-skill first-quest guidance is a bounded landscape composition inside
the actual central workspace, not a narrow mobile-shaped card inside `Center`.
On short desktop windows the workspace remains scroll-safe instead of forcing
the message to grow.

This batch also keeps the desktop shell free from layout-side mutations:
responsive variant calculation is local and pure, with no state writes from
`LayoutBuilder` callbacks.
