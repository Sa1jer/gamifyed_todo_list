# Next Action Lens + Boot Entry MVP - Implementation Decision

## Current behavior

**Repository fact:** the mobile Act overview shows skills, momentum and an
Inbox shortcut. Choosing a Skill opens its task focus. The desktop dashboard
also derives a current task, but neither surface exposes one explicit,
overrideable answer to "what should I do now?" across valid Skill tasks.

`Task` is the persisted completion unit. It owns recurrence, XP, history,
RoadMap stage links, undo and notification behavior. `Minimum Action` is an
optional field on `Task`; marking it complete follows an existing partial-XP
path and, for repeating tasks, can complete the task. `selectedSkillId` is UI
context only and is validated after loading. A focused RoadMap Stage is derived
from the selected Skill's node statuses.

## Candidate approaches

| Approach | Benefits | Costs / risk | Decision |
| --- | --- | --- | --- |
| New persisted Next Action and Boot Entry models | Survive restart and can be audited later. | Duplicates Task focus, requires snapshot migration and lifecycle testing before product evidence exists. | Rejected for MVP. |
| Add metadata to `Task` | Reuses the parent task and can survive restart. | Couples a temporary activation intervention to XP/completion data and makes old task payloads more complex. | Rejected for MVP. |
| Create child Tasks | Uses a familiar UI and completion mechanism. | Clutters lists, can accidentally create XP/Stage progress and turns entry into fake work. | Rejected for MVP. |
| Pure resolver plus session-only Boot Entry | Keeps Task as the single persisted work unit; easy to test and roll back; no schema impact. | User-selected action and Boot Entry are lost on restart. | Selected. |

## Selected representation

### Next Action

`NextActionResolver` is a pure derived view. It receives Skills, Tasks, the
current selected Skill ID and an optional session-only override task ID. It
returns a valid incomplete Skill Task, a concrete action label, context, and an
explainable selection reason. It never mutates models or storage.

The resolver is deliberately not a second task-ranking engine. Its stable
priority is:

1. valid explicit session override;
2. task linked to the selected Skill's active RoadMap Stage;
3. another incomplete task in the selected Skill;
4. task linked to any active Stage;
5. another incomplete Skill task.

Within the same group it preserves current task-list order after existing
priority rank. Inbox tasks are excluded so small errands cannot hide a Skill
path. A task with an unfinished Minimum Action exposes that action as the
concrete entry copy; it does not automatically complete it.

The user override is a short mobile picker of available Skill tasks. It is
session-only, validates the ID on every resolve, and safely falls back if the
task is completed, deleted, moved to Inbox, or its Skill disappears.

### Boot Entry

`BootEntryPlan` is a temporary presentation object linked by parent task and
Skill IDs. It has three user-visible steps:

1. open the relevant quest context;
2. make one small concrete change;
3. inspect the result.

The small-change field prefills from the Task's existing Minimum Action when
available. Without one, it remains required: the app does not invent a
misleadingly specific action from a vague quest title. The user can edit all
copy before starting.

Boot Entry is **not** a Task type and does not replace Minimum Action:

- Minimum Action remains the existing optional, reward-bearing partial
  completion action on a Task.
- Boot Entry is a no-reward contextual work-entry loop around a real Task.
- Completing a Boot Entry does not complete the parent Task, Minimum Action,
  Stage, Goal or RoadMap.
- It grants no XP, history, daily statistics, achievement, buff, chest or
  milestone effects, so repeated creation cannot farm rewards.

After confirmation, the UI acknowledges that the user entered the work and
offers `Вернуться к квесту`; it does not force a longer flow. Dismiss, replace
and edit simply discard or replace the temporary plan without changing the
parent Task.

## Persistence and lifecycle

There is no schema, snapshot, Hive or migration change. The override and Boot
Entry plan do not survive a restart by design. This is acceptable for an MVP
because a durable "where I stopped" record is explicitly deferred to the Return
Context / Save Point decision batch.

The Lens is hidden behind a non-editable explanatory state while persistence is
loading, recovering or in a load-failure block. It does not attempt to bypass
`PersistenceStatus`, startup recovery, or save-failure protections.

## Mobile UX

The mobile Act Overview receives one compact Lens above Skills. It shows the
Skill, the actual action text, a calm explanation of why it was selected, and
two restrained controls: open the parent quest and choose another action.
`Трудно начать?` opens the Boot Entry sheet only for a valid candidate.

Long labels wrap in the content area; primary controls remain at least 44dp.
The Lens is omitted from focused Skill task lists to avoid duplicating the
same information. Desktop keeps its existing Act composition and task
workflows; the resolver has no desktop-only dependency.

## Risks and rollback

- A derived suggestion can still be wrong for the user; the picker and calm
  reason make it overrideable.
- Temporary Boot Entries disappear on restart; this is documented and bounded
  to the MVP rather than masquerading as a Save Point.
- The existing Minimum Action UI rewards a real partial completion; the new
  Boot completion must never call that path automatically.

Rollback is presentation-only: remove the Lens widget and resolver while Tasks,
Minimum Actions, XP, RoadMap and persisted data remain unchanged.
