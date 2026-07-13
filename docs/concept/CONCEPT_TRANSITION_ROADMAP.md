# Concept Transition Roadmap

## Transition rules

- Keep the app usable after every epic.
- Separate presentation experiments from domain and persistence changes.
- Test risky state/mutation boundaries before extraction or migration.
- Preserve desktop behavior while prioritising mobile action-first validation.
- Record failed experiments as evidence, not hidden product debt.

## Epic 1 - Next Action Lens and Boot Entry - implemented MVP

| Field | Plan |
| --- | --- |
| Purpose | Validate whether one explicit next action reduces activation friction. |
| User value | Faster first meaningful move without new project setup. |
| Dependencies | Existing Task ordering, Minimum Action, selected Skill, Review/Nudge selectors. |
| Entities affected | Presentation-only resolver plus session-only Boot Entry plan. |
| Delivered areas | Mobile Act Overview, pure resolver, short override picker, Boot Entry sheet/card, unit/widget tests. Desktop behavior remains unchanged. |
| Schema impact | None. |
| Tests | Selector determinism, stale IDs, completed/Inbox/locked-stage rejection, Minimum Action copy isolation, empty states, 360dp Boot flow and recovery-state coverage. |
| UX validation | Diary: time from open to first real action; clarity rating; dismiss/switch rate. |
| Rollback | Remove Lens/resolver; existing Task and Minimum Action surfaces remain unchanged. |
| Difference from concept | Boot Entry is temporary and carries no XP. It uses editable context/change/inspection copy but does not persist a Save Point. |

## Epic 2 - Return Context Prototype

| Field | Plan |
| --- | --- |
| Purpose | Validate lower-cost return after a pause without first changing storage. |
| User value | Shows latest relevant task/stage/history and one re-entry action. |
| Dependencies | Completion history, selected context, active task, stage status, existing review focus. |
| Entities affected | Derived presentation only. |
| Likely areas | Mobile Act, desktop Act, history selectors, statistics/review links. |
| Schema impact | None for prototype. |
| Tests | Empty history, deleted/stale IDs, recurring reset, one-to-seven-day return simulations, no destructive selection write. |
| UX validation | Return diary and user-reported reconstruction effort. |
| Rollback | Remove card; existing history and task flows remain. |
| Risk / scope | Medium. Do not claim it is a true Save Point. |

## Epic 3 - Voluntary Resistance Intervention

Purpose: offer a non-diagnostic action menu around an existing task. No task
type or permanent state initially. Validate whether users choose a smaller
action, blocker note, or stop point without feeling pressured.

| Field | Plan |
| --- | --- |
| User value | A valid way to change the entry strategy without calling the user lazy or changing task completion semantics. |
| Dependencies / areas | Epic 1 selectors, Task details, mobile/desktop action surfaces. |
| Entities / schema | Presentation-only, no schema. |
| Tests / validation | Dismissal, action selection, minimum-action route, unchanged XP/undo, pressure/shame interview prompts. |
| Rollback / risk / scope | Remove the presentation path; low-medium risk, small-medium scope. |

## Epic 4 - Definition of Done and Proof Prototype

Purpose: test optional outcome/finish prompts using existing description and
completion UI before adding structured persistent fields. Do not make prompts
mandatory for task completion or XP.

| Field | Plan |
| --- | --- |
| User value | Helps define enough and makes real-world movement visible without a new reward rule. |
| Dependencies / areas | Existing description, completion feedback, history UI. |
| Entities / schema | No schema first; structured fields only after prototype evidence. |
| Tests / validation | One-tap completion remains possible; prompts skip safely; finish and result diary study. |
| Rollback / risk / scope | Remove prompts without data cleanup; medium UX risk, medium scope. |

## Epic 5 - Save Point Decision and Durable Design

Only begin after prototypes show repeated return value. This is a medium/large
domain batch: define ownership, edit/delete/undo behavior, snapshot migration,
legacy compatibility, fault injection, lifecycle behavior, and privacy.

| Field | Plan |
| --- | --- |
| User value | Durable, user-authored return context across interruption and restart. |
| Dependencies / areas | AppState mutation map, storage snapshot/manifest, lifecycle/recovery docs, task/stage/history selectors. |
| Entities / schema | Likely additive persisted state; migration and rollback plan required. |
| Tests / validation | Fault injection, startup/dispose, deletion/undo, stale IDs, migration and manual return flows. |
| Rollback / risk / scope | Feature flag or additive model; high architecture risk, large scope. |

## Epic 6 - Quest Chain and Focus Boundary

Add a user-visible chain only if derived views fail to express real sequence.
Decide whether Main/Side Quest is a tag, a focus preference, or a relationship.
Do not introduce global single-focus enforcement without evidence.

| Field | Plan |
| --- | --- |
| User value | Shows local sequencing and focus without forcing every task into a category. |
| Dependencies / areas | Task ordering, stage links, selected Skill, planning and mobile Act. |
| Entities / schema | Derived view first; persistent order/roles only after a product decision. |
| Tests / validation | Branching stages, recurring and Inbox exclusions, focus switching, no forced taxonomy. |
| Rollback / risk / scope | Keep read-only first; medium risk, medium-large scope. |

## Experimental, later, or not yet justified

- AI decomposition and summaries.
- Body-doubling integrations.
- Capacity prediction or automatic energy inference.
- Ambient focus systems.
- Reward economy expansion.
- Persistent Side Quest/Main Quest taxonomy.
- Any RoadMap topology or XP formula rewrite.

## Recommended order

1. **Next Action Lens and Boot Entry**: smallest, presentation-first validation
   of the core doctrine.
2. **Return Context Prototype**: tests the RETURN promise without schema change.

Only after those two show value should the product decide whether durable Save
Points or structured Definition of Done deserve model/storage changes.
