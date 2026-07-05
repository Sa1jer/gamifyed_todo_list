# Desktop Visual System

Last updated: 2026-07-04

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
windows. Statistics reuses `ProgressHubContent`; Trophies reads the existing
buff/chest state directly; Settings exposes common interface preferences and
keeps the richer profile editor as an explicit secondary action.

RoadMap selection stays synchronized with the sidebar skill ID. Camera
centering was adjusted without changing canvas paint, node geometry, graph
ordering, or persistence. Short vertical paths receive additional top space,
while horizontal paths sit slightly lower in the available canvas.

Skill and quest context actions use stable vertical-ellipsis hit regions that
fade on hover/focus without changing row geometry. Reordering remains on the
existing delayed-drag gesture. A skill that has never contained a quest shows
one compact first-quest explanation and relies on the header CTA, avoiding a
second competing action.

## Follow-up Validation

- Compare pointer and scaling behavior on physical Windows QHD at 125% and 150%.
- Compare native macOS density at 1440, 1920, and 2560 widths.
- Profile rebuild boundaries with very large skill/task histories if real data
  shows frame pressure.
- Revisit minor visual spacing only after side-by-side native screenshots; do
  not alter domain behavior during that polish.
