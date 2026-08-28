# Welcome And Tutorial Architecture

Last updated: 2026-08-28

## Product Boundary

First-run guidance has three deliberately separate layers:

1. **Welcome** explains the product promise and local-data boundary before the
   application shell appears.
2. **Interactive Core** teaches only `Навык -> Квест -> следующее действие`.
3. **Guided Product Tour** is an optional, read-only presentation session that
   walks through the real Act, RoadMap, Statistics, Trophies, and Profile
   surfaces. Any topic can also be replayed independently.

Welcome and replay never create sample data, complete a Task, grant XP, open a
reward, or alter Goal, RoadMap, History, or settings. Core may create a real
Skill and Quest only when the user saves their normal creation forms. Its last
step is an acknowledgement, not an automatic completion.

## Startup And First Run

```text
application start
  -> StorageService load
  -> PersistenceGate
       -> load failure: recovery UI
       -> successful load: Welcome decision
            -> unseen fresh install: Welcome
            -> existing install or Welcome seen: application shell
                 -> first relevant Core step
```

Recovery always wins. Welcome is never shown while persisted data is failed or
unresolved. `Начать` stores the device-local Welcome marker and continues into
Core without creating domain data.

Core contains exactly three user-facing steps:

1. Create the first Skill through the real Skill form.
2. Create the first Quest through the real Quest form.
3. Identify the next useful action; completion and XP are not required.

Cancelling either form does not advance. After Core, the user chooses
`Показать остальное` or `Начать пользоваться`; the longer tour is never forced.

## Persisted History And Session Runtime

`TutorialProgress` remains the persisted compatibility/history authority. It
answers which modules and steps were seen and retains active first-run progress
for restart compatibility. Its storage shape and legacy IDs are unchanged.

`GuidedTourSession` is presentation-only runtime state. It owns a plan, current
index, and the phases `presenting`, `leaving`, `navigating`,
`waitingForAnchor`, `entering`, `paused`, and `completed`. It owns no Hive data,
domain models, `BuildContext`, navigation routes, or timers.

A full replay is built from `GuidedTourPlan.fullProductTour`; it never uses
historical `firstIncompleteStep` selection. Therefore previously completed
chapters are still replayed, while completed history remains intact. Restarting
the tour restarts only the in-memory session and never reopens Welcome.

## Ownership

| Area | Owner | Responsibility |
|---|---|---|
| Persisted compatibility | `TutorialProgress`, `TutorialCoordinator`, `TutorialCatalog` | Existing module/step identities, normalization, and first-run history. |
| Pure tour plan | `guided_tour_plan.dart` | Ordered Core/full/topic plans, destinations, semantic anchors, and missing-target policy. |
| Pure session | `guided_tour_session.dart` | Session index and transition state without Flutter or domain dependencies. |
| Session presentation | `guided_tour_session_controller.dart` | One listenable session plus a narrow active-anchor signal. |
| App bridge | `guided_tour_app_coordinator.dart` | Scalar persisted-state sync and explicit first-run callbacks; no AppState import. |
| Navigation | `guided_tour_navigation_coordinator.dart` | Leave, navigate, wait, enter ordering and safe disposal. |
| Temporary routes | `guided_tour_surface_controller.dart` | Mobile/Profile route readiness, manual close, Back, and cleanup. |
| Semantic targets | `tutorial_anchor_registry.dart` | Stable anchor keys, live geometry, bounded readiness, and cancellation. |
| One visual host | `guided_tour_host.dart` | Spotlight, one coach card, focus, keyboard, semantics, and motion. |
| Training Center | `tutorial_training_center.dart` | Full replay, genuine full-tour continuation/restart, and topic replay. |
| Product routing | `main_page/shell.dart` | Binds abstract destinations to the normal desktop/mobile product surfaces. |

Files in `lib/tutorial/` remain framework-free and must not import Flutter,
widgets, AppState, or persistence. Presentation coordinators do not mutate
domain data directly; Core mutations are explicit callbacks to normal product
forms, and replay has no mutation callback.

## Real-Surface Navigation

Every navigation step follows one sequence:

```text
presenting -> leaving -> navigate real product surface
  -> wait for route/workspace readiness -> wait for semantic anchor
  -> entering -> presenting
```

No tutorial card is visible while the destination changes. Desktop Statistics
and Trophies use their normal workspaces. Mobile uses the same secondary pages
as ordinary navigation. Profile uses the real profile surface and ends beside
its Training Center. Tutorial-specific Statistics/Rewards dialogs and nested
tutorial overlays were removed.

The `GuidedTourSurfaceController` distinguishes a user closing a temporary
route from a route replaced by tutorial navigation. Mobile system Back and
desktop close pause a resumable full tour and release route references. All
in-flight destination and anchor waits are cancellation-safe after disposal.

## Semantic Anchors And Missing Targets

The plan names intent (`navRoadmap`, `statisticsSummary`, `profileTraining`),
not widget hierarchy. Product widgets register the matching real control or
content region. The registry re-reads rendered geometry after layout, scroll,
resize, and route changes; dynamic active keys are limited to the current
anchor so repeated list controls do not share a `GlobalKey`.

Each step declares an explicit missing-target policy:

- `skip`: omit an optional data-dependent detail such as Minimum Action;
- `useParentAnchor`: use a nearby stable product region;
- `coachCard`: explain a concept without pretending a control exists;
- `endChapterSafely`: stop an unusable navigation chapter without trapping the
  user.

Readiness uses a `1200ms` wall-clock bound and lifecycle cancellation. It is not
a fixed visual delay or frame-count timeout.

## Placement And Presentation

There is one root `GuidedTourHost` and at most one explanation card. Desktop
placement evaluates right, left, bottom, and top around the target, rejects
target/reserved-region collisions where possible, then chooses a safe dock.
Mobile uses a stable SafeArea-aware bottom coach presentation above navigation.
Missing targets use their declared policy rather than an arbitrary centered
card.

The highlight is a restrained outline/scrim over the real product; it does not
repaint the target into a fake orange state. A transparent modal barrier blocks
confusing background actions while the current explanation is visible.

## Accessibility And Motion

- The card reports one progress context (`шаг X из Y`) and its title once.
- Primary, previous, and close controls remain reachable at `200%` text.
- Desktop `Escape` pauses/exits cleanly; mobile Back closes a temporary surface
  or pauses the tour without leaving a dead overlay.
- Focus moves to the current card and returns to normal product navigation when
  it leaves.
- Reduced motion removes positional travel while preserving state order.
- Safe-area and bottom-navigation reservations remain part of placement.

## Compatibility

- `welcomeSeen`, `onboardingSeen`, and the `TutorialProgress` schema are
  unchanged.
- Established installs are never forced through Welcome.
- Legacy Core IDs still normalize through `TutorialCoordinator`; progress
  already beyond the short Core is treated as completed Core.
- Stale or removed module/step IDs resolve to a safe known step/end state.
- Reset/replay from Profile does not clear Welcome, completion history, Skills,
  Tasks, XP, RoadMap, rewards, or History.

## Why Tutorial V3 Felt Disconnected

V3 split sequencing among a root overlay, dialog-specific tutorial flags, and
inline hints. Generic fallback cards were often detached from visible controls;
Statistics and Trophies opened tutorial-only dialogs on desktop; navigation
could advance into the next explanation before the new surface visually
settled; and chapter/total progress was not consistently visible. V4 replaces
those parallel owners with one session plan, one host, semantic anchors, and a
single navigation coordinator over real surfaces.

## Rejected Designs

The architecture explicitly rejects tutorial-only Skills/Tasks, tutorial XP or
rewards, reopening Welcome for replay, clearing real tutorial history, one
forced giant onboarding, fake Statistics/Trophies screens, fixed-delay or
frame-count synchronization, placement based only on target Y, arbitrary
centered fallback cards, and multiple tutorial overlays at once.

## Verification Boundary

Automated coverage verifies plans, history/runtime separation, replay data
isolation, navigation order, missing-target handling, collision placement,
scroll tracking, route Back, disposal, large text, reduced motion, Training
Center actions, and MainPage rebuild isolation. Native macOS/Windows focus,
window resize, light/dark visual polish, and physical Android TalkBack/Back at
large text remain release QA gates; they must not be claimed from widget tests.
