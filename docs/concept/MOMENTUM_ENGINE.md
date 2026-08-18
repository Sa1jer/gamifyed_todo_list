# Momentum Engine: derived evidence prototype

## Purpose

`Momentum` answers one narrow question:

> What truthful evidence shows that this thread already has useful movement or
> is close to a meaningful boundary?

It does not choose the globally best Task and does not estimate motivation,
capacity, health, discipline, or willingness. `Next ActionResolver` remains the
only current-action ordering authority.

The product hierarchy is:

```text
Return Context = What thread was I in?
Momentum       = What evidence shows this thread has useful movement?
Next Action    = What valid action can I take now?
Boot Entry     = How can I lower the cost of beginning that action?
```

Momentum is passive evidence. It has no CTA and is visually subordinate to the
actual action.

## Implemented signals

The resolver returns at most one explainable result. Priority is deterministic:

| Priority | Reason | Truth requirement | Current copy |
| --- | --- | --- | --- |
| 1 | `stageOneQuestRemaining` | An existing unlocked Stage has a known target and exactly one required Quest remains. | `До завершения этапа остался один квест.` |
| 2 | `completedStageContinuation` | A Stage was completed recently and the same existing Skill has a valid current/next Stage continuation. | `Предыдущий этап завершён — путь продолжается отсюда.` |
| 3 | `stageNearlyComplete` | An existing unlocked Stage has known progress at or above `67%`, with more than one Quest still required. | `Большая часть этого этапа уже пройдена.` |
| 4 | `goalMeaningfullyAdvanced` | Existing `GoalProgressEngine` output is at or above `75%` and below completion. | `Большая часть пути к этой цели уже пройдена.` |
| 5 | `recentRealProgress` | A valid normal-Skill completion exists in the last seven days. | `Здесь уже есть недавний прогресс.` |
| 6 | `minimumActionAvailable` | The existing valid Next Action has an unfinished Minimum Action. | `Для этого квеста уже есть минимальный шаг.` |

The thresholds and recent window are named resolver constants and are covered
by boundary tests. A percentage is never described as "one remaining" unless
the repository has an actual known count.

## Rejected signals

The prototype deliberately rejects:

- inactivity duration and "return pressure";
- streak preservation, streak loss, daily-use pressure, or FOMO;
- XP/level proximity, because it can promote XP farming over real movement;
- task reward size or urgency;
- invented duration estimates;
- generic motivational or celebratory copy;
- mood, diagnosis, energy, commitment, or productivity inference;
- Inbox quick-task activity as evidence for a normal Skill thread.

These are product rejections, not missing implementation work.

## Architecture

The pure resolver lives in
[`lib/engines/momentum_resolver.dart`](../../lib/engines/momentum_resolver.dart).
It accepts detached scalar records, an explicit `now`, and optional current
Return Context/selected Skill hints. It imports no Flutter, `AppState`, widgets,
models, Hive, notifications, or persistence. `MomentumSnapshot` is immutable
and retains no live `Task`, `Skill`, `HistoryEntry`, `GoalReviewEntry`, or
`SkillTreeNode`.

The narrow projection in
[`lib/features/momentum/momentum_view_data.dart`](../../lib/features/momentum/momentum_view_data.dart)
reuses existing authorities:

- `NextActionResolver` supplies the valid action order and Minimum Action fact;
- `GoalProgressEngine` supplies Goal progress;
- `RoadmapEngine` supplies existing Stage state and graph semantics;
- existing completion-history and AppState helpers supply scalar completion
  facts without changing their behavior.

The adapter does not introduce a second task ranking or copy Goal/RoadMap
progress formulas. It builds detached records and immediately resolves the
snapshot. The result is recomputable and is not cached or persisted.

## Determinism and stale data

When Return Context is active, Momentum is scoped to that same Skill so a
stronger signal from another thread can never be embedded into the current
return card. Without Return Context, signals are ordered by product priority,
then selected Skill, newest evidence timestamp, source order, Skill ID, and
Task ID. Explicit time makes tests deterministic.

Missing/deleted Skills, Tasks, and Stages are discarded. Locked Stages and
completed paths are not presented as current work. Inbox activity is excluded.
Future-dated evidence and evidence outside the recent window do not masquerade
as recent progress.

## Presentation

- When Return Context is visible, its existing card owns one small Momentum
  evidence line for the same Skill before the re-entry action. No second
  recommendation card is added; unrelated Skill evidence is suppressed.
- Without Return Context, mobile Act shows one compact passive evidence card
  before the existing Next Action Lens.
- Desktop Act shows the same evidence as a restrained contextual block inside
  the existing main workspace, not as another dashboard column.

The card has no callbacks. Semantics announce the evidence reason and copy.
Long Russian text wraps, light/dark themes use existing semantic tokens, and
non-essential transitions become immediate when reduced motion is requested.

## Side-effect and persistence policy

Resolving or rendering Momentum must never:

- select a Skill;
- complete a Task or Minimum Action;
- write completion history;
- grant XP or rewards;
- alter Goal or RoadMap progress;
- change Return Context/session dismissal;
- call `notifyListeners`;
- schedule notifications or persistence;
- add a model, Hive type/box, snapshot field, or storage key.

The architecture audit enforces the pure boundary and rejects persistent
Momentum declarations in model/storage areas.

## Failure modes and rollback

Potential product failures are a technically true message that feels
decorative, competes with Next Action, creates pressure, or overstates weak
evidence. Potential logic failures are stale identifiers, recurring completion
misinterpretation, unknown remaining counts, or local progress formulas that
drift from their owners.

Rollback is presentation-safe: remove the Act integration and resolver/adapter.
No stored data needs migration or cleanup.

## Validation plan

Automated tests prove deterministic selection, stale-data safety, engine reuse,
side-effect freedom, responsive rendering, semantics, and regressions. They do
not prove usefulness, motivation, retention, or reduced procrastination.

Use [MOMENTUM_VALIDATION_DIARY.md](MOMENTUM_VALIDATION_DIARY.md) with real work.
Keep, tune, or remove a signal based on factual accuracy, reduced reconstruction
effort, clarity, pressure, and competition with Next Action. Return Context and
Next Action/Boot Entry retain their own still-open diary validation.
