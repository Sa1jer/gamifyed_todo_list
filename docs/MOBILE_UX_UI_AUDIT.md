# Mobile UX/UI Product Audit

Audit date: 2026-07-02

Scope: current Flutter mobile experience, product flow, information architecture,
accessibility, perceived reliability, and Android platform behavior. This is an
audit and implementation roadmap, not a redesign specification.

## Executive Summary

The mobile app has moved beyond a compressed desktop layout. It now has an
adaptive shell, full-screen creation forms, a mobile skill selector, a
vertical-only RoadMap, mobile-safe recovery states, bottom navigation, and
meaningful 360dp widget coverage. The core local-first data path is also much
more trustworthy: startup load failures block destructive writes, save failures
remain visible, and the snapshot/manifest layer can recover a previous valid
snapshot.

The largest remaining product problem is priority, not capability. A user who
opens the app to make progress sees profile chrome, an expanded skill chooser,
the selected task list, and a collapsed "Действовать сегодня" block. The app
contains a strong answer to "what should I do next?", but places that answer
after planning and selection. This increases time-to-value and working-memory
load in the most frequent flow.

There is no reproducible P0 mobile UX blocker in the automated suite. The P0
items are distribution blockers: final application ID, private release signing,
non-placeholder launcher artwork, and release version metadata. The highest UX
work is P1: make resumption and the next useful action primary, harden
accessibility/text scaling, improve form-back safety, and make notification
permission behavior understandable.

## Method And Evidence

The audit used:

- The supplied product principles: UX beyond UI, HEART, speed of result,
  cognitive load, energy-saving behavior, human-readable recovery, information
  architecture, service tunnels, and job stories.
- Static review of the mobile shell, skill/task/inbox surfaces, creation forms,
  RoadMap, goals/reviews/nudges, notifications, persistence recovery, theme, and
  shared controls.
- Existing widget tests at 360dp, including mobile skill expansion/collapse,
  long labels, full-screen AddSkill/AddTask, stable skill/stage attachment,
  vertical RoadMap geometry, centering, and recovery states.
- Flutter guidance to branch on available layout constraints rather than device
  labels, test accessibility explicitly, and profile expensive animation work.
- Android guidance for system back behavior, runtime notification permissions,
  exact alarms, signing, and stable application identity.

No real-device interaction session was performed in this audit phase. The
Android emulator was intentionally closed; the preceding Android validation did
assemble, install, and launch the debug app successfully. Findings about touch
feel, screen-reader order, animation smoothness, keyboard/rotation, and
permission dialogs remain manual-test hypotheses until verified on hardware.

## Principles Applied

1. **Outcome before interface:** success means starting or finishing useful
   work, not merely reaching a screen.
2. **Fast first value:** the shortest path is skill -> quest -> completion ->
   visible progress. RoadMap mastery is optional depth, not a prerequisite.
3. **Recognition over recall:** current context and next action should be visible
   without remembering the last selected skill or where a feature lives.
4. **Intended path is easiest:** the most common action should not require more
   navigation than statistics, rewards, or configuration.
5. **Trust is part of UX:** loading, save failure, recovery, and retry states
   must say what happened, whether data is safe, and what the user can do.
6. **Progressive disclosure:** advanced quest, RoadMap, and RPG systems should
   remain available without dominating the first useful action.
7. **Accessible by construction:** text scale, semantics, focus, target size,
   contrast, and reduced motion are release criteria rather than later polish.

## HEART Evaluation

| Dimension | Current signal | Assessment | Practical measure |
| --- | --- | --- | --- |
| Happiness | Cohesive color coding, progress, XP, milestones, undo, dark/light themes | Strong motivation loop, but dense chrome can feel demanding | Short post-session rating; recovery-error confidence interview |
| Engagement | Daily action, minimum step, streaks, RoadMap, reviews, rewards | Many reasons to return; risk of competing calls to action | Days with one useful completion; minimum-step use; review opens |
| Adoption | Guided first skill and quest, validation, empty-state CTAs | Core creation is learnable; tutorial introduces advanced areas early | Time to first skill, first quest, first completion; abandonment by step |
| Retention | Recurring quests, reminders, goal progress, reviews | Resumption is weak because selected context is not restored explicitly | Return-after-3/7-days completion rate; time to resumed action |
| Task Success | Full-screen mobile forms, stable attachment, swipe completion/undo | Core flows work; next action placement and hidden swipe affordances add effort | Taps/time/error rate for create, complete, undo, and resume journeys |

These measures are a research plan, not a request to add analytics in this
batch. Start with scripted usability sessions and local debug timing before
introducing any telemetry or privacy policy work.

## Key Job Stories

- When I open the app to make progress, I want one useful next action near the
  top, so I can begin without planning again.
- When I have an unrelated thought, I want to capture a quick task immediately,
  so it does not pollute skill progress or disappear from memory.
- When I create a skill, I want to state why it matters and make one first
  quest, so the skill becomes actionable rather than decorative.
- When I create a quest, I want its skill and optional RoadMap stage to be
  unmistakable, so completing it advances the progress I expect.
- When a task feels too large, I want a visible minimum step, so I can preserve
  momentum with less energy.
- When I return after a break, I want to see where I stopped and what is still
  useful, so I do not reconstruct context manually.
- When I finish a quest or goal, I want progress feedback and the likely next
  action nearby, so the reward becomes continued behavior.
- When storage fails, I want to know my existing data is protected and have a
  clear retry, so I do not panic or create conflicting replacement data.

## Current Mobile Information Architecture

```text
App shell
|-- Top bar
|   |-- Trophy/reward state
|   |-- Statistics
|   |-- Sound, theme, help
|-- Profile bar
|   `-- Profile, level, XP, preferences
|-- Bottom navigation
|   |-- Сейчас / Действовать
|   |   |-- Skills (expanded or compact)
|   |   |-- Selected skill quests or Задачник
|   |   `-- Действовать сегодня (collapsed by default)
|   `-- Карта
|       |-- Skill overview
|       |-- Vertical RoadMap canvas
|       `-- Skill/stage/quest details and editing
|-- Statistics (opened from top bar)
|   |-- Growth, calendar, history
|   `-- Weekly review and related secondary views
`-- Overlay feedback
    |-- Tutorial
    |-- Milestones/rewards
    `-- Persistence load/save recovery
```

The taxonomy is internally consistent once learned, but a first-time user must
distinguish Skill, Goal, RoadMap, Stage, Quest, Minimum Step, XP, review,
achievements, rewards, and effects. The two bottom destinations are clear; the
secondary destinations are split between top-bar icons, profile, dialogs, and
the statistics hub. This keeps the bottom bar simple but makes feature location
less predictable.

## Journey Audit

### First Run

Current path: empty Act -> guided skill creation -> guided quest creation ->
completion/minimum step -> RoadMap -> statistics -> trophies/profile modules.

What works:

- Empty states explain the immediate prerequisite and provide direct CTAs.
- Skill and quest creation use mobile full-screen routes rather than squeezed
  desktop dialogs.
- Validation keeps the user in context and names the missing title.
- RoadMap is not required to save the first useful quest.

Friction:

- The tutorial continues into advanced product areas before the core habit has
  repeated, increasing adoption cost.
- Several tutorial overlays compete with the underlying dense shell.
- Success is defined partly as feature exposure rather than first meaningful
  completion and confident return.

### Daily Act

Current path: open app -> choose skill -> inspect quests -> swipe or open action
-> complete/minimum -> receive XP/milestone/reward -> choose next action.

What works:

- Expanded skill cards provide level, active quest count, and goal progress.
- Selection collapses the skill area and preserves more room for tasks.
- Task cards expose minimum actions and support completion, undo, edit, and
  delete through mobile swipe actions.
- Completion feedback connects behavior to progress and rewards.

Friction:

- "Действовать сегодня" is below the task list and collapsed on mobile, so the
  best recommendation is not the first thing seen.
- No selected skill is persisted as a deliberate resumption context; after a
  restart, the user can be returned to choice instead of continuity.
- Swipe actions are efficient after discovery but have weak first-use
  affordance.
- Profile and top-bar controls consume scarce vertical attention before the
  daily action.

### Create Skill

What works:

- The form is scrollable, keyboard-safe, and full-screen below the shared mobile
  breakpoint.
- The first-run copy makes goal and initial stage optional depth rather than a
  blocker.
- Stable IDs and storage behavior are already covered elsewhere.

Friction:

- Icon/color choice and RoadMap concepts arrive before the user has evidence
  that they need customization.
- System Back or the close action discards an edited draft without an explicit
  unsaved-changes confirmation.
- Icon choice and custom controls need screen-reader and large-text verification.

### Create Quest

What works:

- The route captures the originating skill/stage ID, so later selection changes
  cannot attach the quest incorrectly.
- Title validation is inline and human-readable.
- Description, minimum step, behavior, stage, subtasks, tags, reminders, and
  SMARTER guidance use partial progressive disclosure.

Friction:

- XP is presented early even for a simple capture, adding a game-economy
  decision before the job is complete.
- The form is still long for the common case of title + optional minimum step.
- Unsaved Back behavior is not guarded.
- Reminder permission/exact-alarm failure is not explained in the form as a
  recoverable platform constraint.

### Complete Quest

What works:

- Completion and minimum-step actions are fast, animated, and connected to XP,
  skill progress, milestones, achievements, rewards, and reviews.
- Completed tasks can be restored with a swipe action.
- Persistence failures remain observable instead of pretending success on disk.

Friction:

- Multiple simultaneous reward surfaces can compete with the next useful
  action, especially on a small screen.
- The service tunnel after completion is visually rich but not always singular:
  next quest, RoadMap progress, rewards, and statistics may all ask for attention.

### RoadMap Progress

What works:

- Mobile is always vertical; desktop-only orientation/fullscreen controls remain
  hidden.
- Camera centering and 0/1/long-stage geometry have regression coverage.
- Skill, goal, stage status, linked practice, insertion, and reordering share
  stable identities.
- Templates begin collapsed after a skill is selected.

Friction:

- Canvas navigation plus a details panel is inherently high-load on 360dp.
- Labels deliberately ellipsize; a long goal or stage can require opening more
  detail to recover meaning.
- The map does not offer a single explicit "current stage" jump independent of
  general centering.
- Equal-weight stage percentages can look more objectively measurable than the
  underlying text goal really is.

### Goal, Review, And Nudge

What works:

- The 100% state, next-goal flow, goal history, milestones, weekly review, and
  nudge engine form a coherent reflection loop.
- Nudges are based on state rather than generic motivational copy.

Friction:

- Goal meaning, RoadMap completion, skill XP, and profile XP are distinct
  progress systems shown near one another.
- Reviews and nudges are secondary surfaces and can be hard to relocate later.
- A user returning after absence does not get a dedicated "resume gently"
  summary of stale context, overdue reminders, and one safe restart action.

### Storage Recovery

What works:

- Startup load failure replaces the app with a clear recovery screen.
- Copy explicitly says saved data will not be overwritten.
- Retry is visible and technical details are debug-only.
- Save failure appears as a persistent banner and keeps dirty in-memory state.
- Snapshot/manifest loading can fall back to the previous valid snapshot.

Friction:

- Normal startup is a bare spinner with no delayed explanatory text.
- The save-failure banner uses a cloud-off icon even though persistence is local,
  which can imply a network problem.
- There is not yet an export/manual-recovery path for repeated native storage
  failure; this is correctly deferred rather than improvised.

### Notifications

What works:

- Permission awaits are guarded and concurrent requests are deduplicated.
- Reminder failures do not crash task mutation.
- Notification payloads avoid exposing task titles on the lock screen.

Friction:

- Android notification and exact-alarm permission are coupled into one success
  result. Denying exact alarms can make all reminder setup appear unavailable.
- Scheduling uses exact-while-idle with no documented inexact fallback.
- Initialization/scheduling failures are fail-soft but not observable to the
  user, so a reminder can be assumed active when it is not.
- iOS/macOS initialization settings request notification permissions during
  plugin initialization; permission timing should be verified and delayed until
  explicit reminder intent if the platform plugin still prompts immediately.

## Cross-Cutting Friction And Cognitive Load

- The mobile shell gives similar visual weight to daily action, profile growth,
  rewards, statistics, settings, and help.
- Progress appears in several forms: profile XP, skill XP/level, goal percent,
  stage quest target, streak, achievements, and rewards. Each is valid, but the
  relationship is learned rather than self-evident.
- The core verb changes by context: task, quest, practice, minimum step, stage,
  and quick task. Copy should preserve domain depth while making the default
  action consistently recognizable.
- The user must often select a skill before the app can answer what to do next.
- Advanced guidance is generous, but the amount of explanation can itself
  become work on a small screen.

## Human-Readable Error Audit

Strong states:

- Missing skill/quest titles identify the required action.
- Startup recovery says what failed, protects trust, and offers retry.
- Save failure says changes remain in memory and offers retry.

Gaps:

- Notification denial/scheduling failure needs copy that distinguishes normal
  notification permission, exact timing, and an available fallback.
- A long startup should say that local data is being opened, not look frozen.
- Unsaved form dismissal should warn only after a draft becomes dirty.
- Repeated recovery failure should eventually link to a safe support/export
  procedure without exposing raw exceptions in release.

## Visual Hierarchy Audit

Strengths:

- Consistent panel geometry, semantic skill colors, clear completed-state green
  fallback, coherent dark/light surfaces, and restrained standard motion.
- Mobile skill cards encode several values compactly without requiring a table.
- Major creation actions use explicit labels rather than icon-only controls.

Issues:

- `ThemeData` has no product `TextTheme`; many local hard-coded font sizes make
  hierarchy and large-text behavior difficult to govern.
- Mobile top/profile chrome is now compact, but the remaining desktop-first
  type constants still limit how confidently the hierarchy scales above 130%.
- Many icon controls are 28-42dp visual boxes or custom gesture surfaces; visual
  density is good for desktop but must be checked against mobile target size.
- The default Flutter Android launcher icon and basic launch background do not
  represent the RPG product and weaken perceived release quality.
- Reward/milestone overlays can stack attention even when each animation is
  individually polished.

## Accessibility Audit

Existing strengths:

- Goal progress has an explicit semantic value.
- Many icon-only controls have tooltips.
- Mobile bottom navigation is inside `SafeArea`.
- Creation forms scroll with the keyboard and dismiss it on drag.
- RoadMap text geometry receives the current `TextScaler`.
- The mobile skill panel respects the platform disable-animations flag.

Confirmed gaps:

- There are no automated `meetsGuideline`/SemanticsTester accessibility gates.
- There is no 200% text-scale mobile regression suite.
- The app lacks a centralized text hierarchy and uses extensive local font
  sizing/ellipsis.
- Custom `GestureDetector`/`PressFeedback` controls do not consistently declare
  button/toggled semantics independent of tooltip behavior.
- Focus traversal and screen-reader order have not been validated for forms,
  canvas controls, swipe actions, overlays, or dialogs.
- Reduced motion is not app-wide; switchers, XP bubbles, milestones, confetti,
  and theme reveal need a common policy.
- Contrast has not been measured systematically across every user-selected skill
  color in both themes.

## Mobile Platform Audit

- **System Back:** full-screen forms use Navigator routes, but dirty drafts have
  no `PopScope` confirmation. Predictive Back and cancellation should be tested
  on Android 15/16 without replacing system navigation.
- **Keyboard:** `adjustResize`, scrollable forms, `SafeArea`, and keyboard-dismiss
  behavior are good foundations. Test small-height landscape and large text.
- **Safe areas:** bottom navigation and recovery surfaces account for insets;
  overlay banners and milestone placement still need device-cutout testing.
- **Orientation:** no portrait lock was found. The product has portrait-focused
  coverage but no explicit narrow-landscape acceptance test.
- **Performance:** theme switching captures a frame at up to 2x DPR; this is a
  sensible cap, not proof of smoothness on lower-end hardware. Profile it in
  profile mode. Large RoadMaps and reward overlays need frame-timing probes.
- **Profile image:** the picker loads bytes into memory without a confirmed
  decode-size/input bound; very large files remain a memory-pressure risk.
- **Permissions:** notification/exact-alarm flow needs a graceful degraded mode
  and policy decision before store submission.

## Quick Wins

Implemented on 2026-07-02:

1. Mobile "Сейчас" keeps skills first, then shows a compact next-action summary
   before the task list. It exposes either the minimum step or the next quest
   with a labelled `48dp` primary action and remains expandable into the full
   dashboard.
2. Empty selected skills now explain why a quest matters, recommend a minimum
   step, and offer a direct "Создать квест" action.
3. Dirty mobile AddSkill/AddTask forms intercept close and Android Back with a
   calm keep-editing/discard choice. Untouched forms still close immediately;
   desktop dialogs are unchanged.
4. Minimum-step hints use clearer "Начни с этого" copy, wrap to two lines, and
   expose a semantic label. The compact dashboard expand control now has a
   `48dp` target and expanded state semantics.
5. Local save failure now uses a storage-neutral warning icon and explains that
   changes are not yet written to the device but remain open for retry.
6. Widget coverage now protects next-action placement/action, empty-skill CTA,
   dirty AddSkill close, dirty AddTask system Back, and save-failure copy.

### Mobile Visual System Redesign Epic

Implemented on 2026-07-02 without model/storage changes, RoadMap engine changes,
or goal-progress formula changes. The only product-logic change is the approved
fixed `+10 XP` reward for quick tasks:

1. The identity header now gives profile XP numeric and visual weight while
   retaining the captured-state overflow sheet, reward badge, and hidden debug
   entry. Draft mobile colors, spacing, radii, and motion live in local
   `MobileJournalTokens`; the global and desktop themes were not migrated.
2. `Сейчас` has two presentation-only states. Overview contains honest daily
   momentum, compact full-width skill cards with goal-progress rings, the global
   next action, and a separate Inbox accordion. Focus replaces that overview
   with a readable stable-ID skill switcher, explicit `Обзор`, and one task
   surface with separate skill XP and goal progress.
3. Inbox is no longer selected as a normal mobile skill. Its low-opacity
   accordion exposes input, all quick tasks, count, and `+10 XP` pills. Quick
   completion and undo update profile XP and today's XP/action count only; they
   remain isolated from skill XP, RoadMap, history, buffs, achievements, chests,
   and milestones. Desktop keeps the system-skill layout and shared XP copy.
4. Mobile RoadMap defaults to `Путь навыка`: a scroll route built from the
   existing `RoadmapEngine` snapshot/path layout, runtime branch pills, semantic
   stage states, compact progress, and safe details/templates sheets. The
   unchanged InteractiveViewer is available as `Свободная карта`; desktop keeps
   canvas-first behavior.
5. Mobile AddSkill now has a live emblem rather than a fake skill card,
   meaningful icon semantics, non-persisted category filters, squircle color
   swatches, dirty-draft protection, and one bottom SafeArea CTA. Desktop and
   AddTask submit behavior remain unchanged.
6. The mockups supplied hierarchy, atmosphere, and navigation direction, but
   were intentionally not copied pixel-for-pixel. No fake metrics, dual rings,
   new economy, assets, fonts, packages, graph mutations, or Quest Log were
   introduced.
7. Widget coverage protects Overview/Focus, honest momentum, Inbox accordion,
   stable reorder IDs, isolated XP/undo, linear/branch paths, free-map fallback,
   templates, AddSkill semantics, and dark/light layouts at
   `360/393/430/700dp`; the `360dp` path also runs at `200%` text scale.

Dark mode is the polished target. Light mode has a warm usable fallback with
readable text/icons and no broken gradients, but `Light Journal Palette Polish`
remains a dedicated follow-up. Remaining work also includes app-wide typography
and design tokens, broader `200%`/screen-reader/focus-order gates, physical-device
motion/keyboard QA, additional RoadMap/icon polish, and Android release QA.

Remaining quick wins:

1. Extend the new `200%` mobile journal test into app-wide semantic button,
   tap-target, focus-order, and screen-reader gates.
2. Add delayed startup copy after a short spinner-only interval.
3. Add a first-use hint for mobile swipe actions, then retire it after discovery.
4. Verify and improve reminder copy for notification denial, exact-alarm denial,
   and scheduling failure; offer inexact timing when product requirements allow.
5. Restore a last-active skill as device-local presentation state, with a clear
   way to return to the skill chooser.
6. Stop the mandatory core tutorial after first useful completion; present
   RoadMap, statistics, trophies, and profile as optional learn-more modules.
7. Create final launcher/splash artwork and replace placeholder metadata before
   release.
8. Design a real streak model and stats contract before adding richer streak
   metrics; Overview currently shows only an honest positive existing streak.

Quest Log Presentation Layer remains explicitly deferred. If pursued, it should
first be a presentation-only view over existing task/skill/stage identities,
without new persistence entities, XP rules, or RoadMap semantics.

## Larger Redesign Candidates

These are hypotheses for separate discovery/implementation batches, not
approved changes:

- If usage feedback shows the compact summary is insufficient, explore a deeper
  mobile "Сейчас" recomposition without introducing a separate Quest Log.
- Validate the new compact mobile chrome and secondary-destination sheet with
  real use, especially reward discoverability and one-handed reach.
- Build a gentle return-after-absence surface that summarizes the last active
  goal, one restart action, and optional review.
- Define a product typography/token system for compact, regular, and large-text
  layouts before visual polish spreads more local constants.
- Add a RoadMap "current stage" focus mode that reduces canvas navigation while
  preserving the full map as optional context.
- Clarify the relationship among skill XP, goal percentage, stage mastery, and
  profile XP through one consistent explanatory model.

## Prioritized Roadmap

### P0 — Release And Trust Blockers

- Choose and apply a final owned Android application ID/namespace before first
  publication; do not change it after Play distribution.
- Configure the private upload keystore locally and produce signed APK/AAB
  probes without committing secrets.
- Replace the default launcher icon, bump build number, and verify release
  metadata and store-visible permissions.
- Complete real-device recovery and process-kill tests before claiming storage
  reliability for release.

No P0 core-flow defect was reproduced in the current 291-test suite.

### P1 — High-Friction Mobile Flows

- **Implemented:** make the next useful action primary on mobile "Сейчас" while
  preserving the skills-first composition and full dashboard expansion.
- **Implemented:** add dirty-draft Back protection to full-screen creation forms.
- Add accessibility gates: semantics, targets, 200% text scale, screen-reader
  order, and app-wide reduced motion.
- Decouple notification permission from exact-alarm capability and define a
  visible fallback/error state.
- Shorten mandatory first-run guidance to first value; keep advanced modules
  optional.
- Bound/downsample profile image input before full byte decode.

### P2 — Repeated Confusion And Cognitive Load

- Introduce a shared `TextTheme`/responsive type scale and reduce ad hoc
  ellipsis at 360/393/430dp.
- Persist or derive a safe last-active context and add a return-after-absence
  nudge.
- **Implemented:** unify mobile top/profile chrome and group secondary
  destinations while keeping reward state visible.
- Explain the four progress systems consistently and label equal-weight goal
  percentages as RoadMap progress until goals become measurable.
- Add current-stage focus and long-label disclosure to mobile RoadMap.
- Add delayed loading copy and repeated-recovery support guidance.

### P3 — Visual Polish

- Audit contrast for every selectable skill color in both themes.
- Normalize icons, target sizes, spacing, and state feedback through shared UI
  tokens.
- Profile theme reveal, large RoadMaps, and reward overlays on low/mid-tier
  Android hardware.
- Create product-specific splash/launcher assets and verify light/dark launch
  continuity.

### P4 — Optional Delight

- Tune milestone/reward concurrency so celebration never hides the next action.
- Add optional richer RPG atmosphere only behind sound/reduced-motion settings.
- Explore user-selectable feedback intensity after the core flow and
  accessibility work are stable.

## Recommended Next Batch

Run a focused **Mobile Accessibility + Large Text Hardening** batch:

1. Characterize shared custom controls, screen-reader order, contrast, focus,
   and text scaling before changing global typography.
2. Add 360/393/430dp and 200% text-scale regression coverage.
3. Fix remaining icon/color picker and task-swipe semantics/tap targets locally.
4. Profile reduced-motion behavior without adding new animation systems.
5. Keep notification/exact-alarm behavior in a separate Android permissions
   batch because it changes platform behavior and store policy.

## Reference Checklist

- Flutter adaptive layout: <https://docs.flutter.dev/ui/adaptive-responsive/general>
- Flutter SafeArea and MediaQuery: <https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery>
- Flutter accessibility: <https://docs.flutter.dev/ui/accessibility>
- Flutter accessibility testing: <https://docs.flutter.dev/ui/accessibility/accessibility-testing>
- Flutter performance practices: <https://docs.flutter.dev/perf/best-practices>
- Flutter Android Predictive Back: <https://docs.flutter.dev/release/breaking-changes/android-predictive-back>
- Android Predictive Back: <https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture>
- Android exact alarm behavior: <https://developer.android.com/about/versions/14/changes/schedule-exact-alarms>
