# Current Product Model

## Evidence boundary

This is a **repository fact** map as of version `1.3.61+1`. It describes the
current application, not the preferred future product. Source areas include
`models.dart`, `app_state.dart`, `engines/`, mobile Act, planning, RoadMap,
statistics, and persistence documentation.

## Current primary journey

1. Create or choose a **Skill**.
2. Optionally describe a **Goal** and add RoadMap stages.
3. Create a **Task**, normally attached to a Skill and optionally to a stage.
4. Start its **Minimum Action** or complete the task.
5. Receive XP, feedback, history, milestone, achievement, chest, buff, and/or
   review effects according to the existing completion path.
6. Use RoadMap, Statistics, Review, and Nudge surfaces to decide what to do
   next.

The current visible core loop is action-first, but its conceptual load is high:
Skill, Goal, RoadMap, Stage, Quest, Minimum Step, XP, review, rewards,
effects, and statistics can all appear around one action.

## Current entities and responsibilities

| Entity or system | Repository fact | Current execution value | Current friction risk |
| --- | --- | --- | --- |
| Skill | Persistent container with goal, XP, stages, goal history, completed-roadmap history, color, and icon. | Groups related work and progress. | The name can imply a lifelong capability when the user is trying to finish a bounded project. |
| GoalSpec | Persistent text, optional metric/deadline/current value, and reviews. | Gives direction and supports weekly reflection. | A text goal does not itself define the next physical action. |
| RoadMap / Stage | Persistent stage graph with prerequisite IDs, checklist, quest target, and mastery state. | Connects practice to a longer path. | Planning structure can become another prerequisite before starting. |
| Task / Quest | Persistent title, description, XP, type, recurrence, priority, minimum action, subtasks, tags, stage link, notification fields, and completion data. | Represents executable work. | Many optional fields can compete with simple capture. |
| Minimum Action | A task string that can be completed for partial XP before full completion. | Existing low-friction entry mechanism. | It is not yet a complete return/context loop. |
| Inbox / quick task | System-scoped task without Skill, RoadMap, or skill XP; completion gives fixed profile/today XP. | Fast capture and small errands. | It intentionally cannot represent project context or a meaningful next action. |
| Review | Weekly, goal-linked reflection with wins, blockers, adjustment, and next focus. | Supports reassessment and explicit blockers. | It is periodic and may arrive after friction rather than at the moment of friction. |
| Course Nudge | Pure engine chooses one suggestion: create focus quest, clarify focus, add minimum action, create stage quest, or clarify goal. | Existing diagnostic/advisory layer. | It is one recommendation among several secondary surfaces, not an always-visible execution contract. |
| XP / level | Completion feedback for profile and Skill; quick inbox tasks are isolated. | Makes progress legible. | XP can become a target separate from real-world movement. |
| Achievements, chests, buffs, boss/reward systems | Completion-driven feedback systems with persistent state. | Celebration and optional novelty. | Cognitive and motivational overhead can exceed their execution value. |
| History / statistics | Completion history, daily stats, weekly goals, progress and trophies. | Evidence of completed work and reflection. | It describes past work more reliably than it prepares return to unfinished work. |

## What determines attention today

### Selected Skill

**Repository fact:** `AppState.selectSkill` validates current IDs and the UI
keeps a selected normal Skill for Act, RoadMap, and desktop workspace context.
The Inbox system ID is intentionally separate. Selection is useful context, but
it is not a durable user-authored "where I stopped" record.

### Active Quest

**Repository fact:** active tasks are non-completed Skill tasks. Existing
ordering uses task ordering and priority rules; mobile focus shows the selected
Skill's active work. `CourseNudgeEngine` can recommend a task to create or
clarify, and `ReviewEngine` can draft a next focus.

**Inference:** current attention is derived from available work and current UI
selection, not from one explicit commitment that the user can resume after a
pause.

### Next Action Lens MVP

**Repository fact (MVP implementation):** mobile Act Overview now resolves one
valid incomplete Skill task through a pure `NextActionResolver`. A temporary
user choice can override the suggestion during the current session. The
resolver prefers an active-stage task in the selected Skill, then other work in
that Skill, then active-stage work elsewhere, while excluding Inbox, completed,
missing-Skill, and locked/missing-stage tasks. It does not persist a focus or
modify Task ordering.

**Repository fact (MVP implementation):** Boot Entry is a session-only,
user-editable three-step entry loop around a valid parent Task. It is not a
Task, does not write to storage, and has no XP, history, RoadMap, Goal, reward,
achievement, buff, chest, or statistics effect. Restarting intentionally clears
both the override and Boot Entry; durable return context remains deferred.

### Goal, RoadMap, and stage progress

**Repository fact:** goal progress is stage mastery divided by the number of
unique stages. RoadMap stages unlock from prerequisite mastery; completion
counts for linked quests inform a stage's current/next/locked presentation.
Goal text and stage topology are meaningful context, but neither guarantees a
clear next physical action.

## Completion and return behavior

### Minimum Action

**Repository fact:** a task's optional `minimumAction` can be marked complete
without completing the task. It records its own completion time and earned XP.
The normal full completion/undo path remains separate and high-risk.

### XP and feedback

**Repository fact:** full task completion updates XP, daily statistics,
history, recurring state and relevant reward/achievement checks. Inbox tasks
use a deliberately isolated `+10 XP` path and do not advance RoadMap or Skill
XP. Existing behavior must remain unchanged until a separate product decision.

### Review and Nudge

**Repository fact:** ReviewEngine uses a seven-day cadence and recent
completion history. CourseNudgeEngine assesses review focus, missing minimum
actions, active stages without practice, and weak goals.

### Stored return context

**Repository fact:** the app persists skills, tasks, history, goals/reviews,
RoadMap state, rewards, statistics, UI preferences, and recovery snapshots.
It does not currently persist one explicit Save Point containing the user's
last context, blocker, completed result, and first return action.

## Motivation versus execution support

| Directly helps execution | Mainly motivation or feedback | Mixed |
| --- | --- | --- |
| Task title, stage link, Minimum Action, active stage, review next focus, Course Nudge, Inbox capture, reminder settings | XP, levels, achievements, chests, buffs, milestone animation, rank visuals | Goal, RoadMap, weekly goal, statistics, history, recurring streaks |

**Inference:** the app already contains valuable execution primitives. The
future product should make those primitives easier to enter and resume before
adding another reward layer.

## Current decision burden

1. A new user may choose a Skill, goal, icon, color, stage, task type, XP,
   minimum action, recurrence, tags, subtasks, reminder, and priority before
   learning whether one action helps.
2. A returning user can see a task list but lacks one explicit saved answer to
   "what was I doing, why, and what is the smallest useful re-entry?".
3. A user can complete useful Side-Quest-like work without an explicit visual
   distinction between maintenance, exploration, and movement of the intended
   project.
4. XP and rewards are visible after work, while observable project evidence is
   optional or implicit in task titles/history.

## Product contradictions to resolve

- **Repository fact:** RoadMap is framed as a mastery path. **Product
  hypothesis:** some users need a bounded project outcome before mastery.
- **Repository fact:** Minimum Action lowers entry cost. **Inference:** it is
  not enough when context reconstruction or emotional resistance is the main
  blocker.
- **Repository fact:** recurrence exposes streak-related feedback. **Product
  principle:** absence must not be presented as a moral failure or erased
  journey.
- **Repository fact:** Course Nudge can identify missing clarity. **Inference:**
  its helpfulness depends on being offered at the right moment with a low-cost
  response, not merely on correct detection.

## What this map does not claim

It does not claim that all users need a Main Quest, that any current mechanic
causes harm, or that the product treats executive dysfunction. Those are
future hypotheses requiring voluntary user validation.
