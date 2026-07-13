# Future Domain Model

## Decision rule

This is a conceptual model, not a migration proposal. Prefer a derived view,
presentation mode, or existing-model extension before adding a persistent
entity. Any later schema change must separately cover legacy data, snapshot
compatibility, rollback, and AppState mutation boundaries.

| Current or candidate concept | Current responsibility | Proposed future responsibility | Keep / naming | Best first shape | Alternative | Persistence and migration risk |
| --- | --- | --- | --- | --- | --- | --- |
| Skill | Long-lived container for goal, XP, RoadMap, and tasks. | Stable area of practice or project context. | Keep model; consider UI label "Направление" only after research. | Existing `Skill`. | New Project entity. | Low now; new Project model would be high risk. |
| Goal | Text/metric/deadline/review attached to Skill. | Direction and acceptable outcome, not a daily command. | Keep. | Existing `GoalSpec`. | Split outcome and metric. | Low for presentation; medium if structured outcome changes. |
| RoadMap | Stage graph for mastery. | Optional path of capability or project milestones. | Keep; make secondary to immediate action. | Existing graph. | Separate project plan. | High if topology changes; do not use first. |
| Road | Runtime template path. | A branch of the path, not a user-facing core entity by default. | Keep technical term internal. | Existing `RoadmapPath`. | Persistent Road model. | High / unnecessary. |
| Stage | Prerequisite-aware mastery milestone. | Meaningful checkpoint or chapter. | Keep. | Existing `SkillTreeNode`. | Project phase model. | Medium/high; defer. |
| Task | Executable unit with completion semantics. | Underlying work record. | Keep technical model. | Existing `Task`. | Replace with Quest model. | High migration risk; do not rename in storage. |
| Quest | Current UI language for Task. | User-facing actionable commitment. | Keep as presentation term. | Task UI copy. | Separate entity. | No need for separate model. |
| Main Quest | Does not exist. | Limited intentional project focus. | Add only after value validation. | Derived selected normal Skill plus chosen active Task. | Persistent `mainQuestId`. | None for prototype; medium for durable explicit choice. |
| Side Quest | Does not exist. | Useful but non-primary work, including exploration/maintenance. | Concept only initially. | Derived view based on focus and stage relation. | Task flag/tag. | Low if tag reuse; risk of shameful classification. |
| Boot Quest | Does not exist. | Short entry sequence that lowers activation energy. | Do not create task type first. | Generated intervention over task/minimum action. | Separate task subtype; temporary session plan. | None for MVP; subtype would expand completion rules. |
| Resistance | Does not exist. | Voluntary signal that asks for a different entry strategy. | Keep non-diagnostic. | Ephemeral intervention mode. | Persistent task state; separate Quest. | None first; persistent state requires careful semantics. |
| Next Action | Exists only as derived task/nudge/focus. | One explicit physical action for the current context. | Make core presentation concept. | Derived selector from active task, minimum action, stage, review focus. | User-pinned field. | None first; explicit persistence later may be worthwhile. |
| Minimum Step | Task string with separate completion/XP data. | Existing low-friction action, optionally used by Boot mode. | Keep behavior unchanged. | Existing fields. | Replace with Boot Quest. | Do not alter completion semantics. |
| Quest Chain | Does not exist. | Visible sequence of local work outcomes. | Add as derived view first. | Existing ordered tasks + stage links. | Persistent ordered chain entity. | None first; medium if user-managed chains prove valuable. |
| Definition of Done | Does not exist. | Explicit enough boundary for finishing. | Introduce only after copy/usability research. | Optional structured section of description. | Dedicated Task field. | None first; medium for durable structured semantics. |
| Proof of Progress | Implied in task/history title only. | Observable real-world result of a completed cycle. | High-value hypothesis. | Optional completion reflection in transient UX. | Persistent evidence field/attachment. | None for test; medium/high for stored attachments. |
| Save Point | Does not exist. | Return context: stop point, result, blocker, next action, opening cue. | Core candidate after validation. | Derived return summary from history/task/stage. | Dedicated linked persisted record. | None for prototype; medium/high once durable. |
| Journey | Existing history/reviews and recurrence/streak data. | Non-punitive continuity framing. | Presentation concept. | History/review summary. | New journey model. | None required initially. |
| Review | Goal-linked weekly reflection. | Checkpoint to adjust direction, blockers, and focus. | Keep; make optional and contextual. | Existing `GoalReviewEntry`. | Separate session review. | Existing model sufficient initially. |
| Nudge | Rule-based CourseNudge recommendation. | Calm, optional intervention selector. | Keep engine; reconsider placement/copy. | Existing `CourseNudgeEngine`. | AI-only nudge system. | No schema impact; AI must not be required. |
| XP | Completion feedback and progression. | Secondary acknowledgement of real cycles. | Keep, reassess emphasis. | Existing XP rules. | Outcome-weighted XP. | High domain risk; defer. |
| Achievement | Persistent unlock feedback. | Occasional recognition, not task selection. | Supporting/optional. | Existing engine. | Remove / replace. | Avoid migration without evidence. |
| Reward / chest / buff | Persistent reward economy. | Optional novelty after real progress. | De-emphasise before removing. | Existing systems. | Retire later. | Medium product and migration risk. |
| Weekly Goal | Persistent weekly title and key results. | Optional planning horizon. | Keep as secondary. | Existing `WeeklyGoal`. | Main Quest substitute. | Do not conflate with daily focus. |

## Recommended conceptual boundary

**Recommendation - product hypothesis:** retain the existing persistence model
for the first validation cycle. Make `Next Action`, Boot mode, Resistance,
Quest Chain, and Journey presentation/derived concepts. Do not make Main Quest,
Save Point, Proof of Progress, or Definition of Done persistent until users
demonstrate that the lightweight versions help rather than add form burden.

## MVP status - Next Action and Boot Entry

The first implementation follows this boundary without a schema change:

- `Next Action` is a pure resolver result over existing Skills, Tasks, selected
  UI context, active stages, priority, and list order. A chosen alternative is
  session-only and revalidated whenever the resolver runs.
- `Boot Entry` is a temporary plan linked by parent Task and Skill IDs. It is
  not a child Task, does not consume or complete Minimum Action, and is lost on
  restart.
- `Minimum Action` remains the only existing partial-completion path with XP.
  Boot Entry can prefill from it but never invokes it automatically.

This preserves the decision rule: no durable focus/return model until a later
Return Context experiment shows that restart persistence is worth its storage
and lifecycle cost.

## Model-change trigger

Only consider a persistent extension when all apply:

1. The user cannot reliably recreate the value from existing Task, Skill,
   Stage, review, and history data.
2. The concept survives across sessions and affects a meaningful return flow.
3. A prototype shows users voluntarily use it and benefit from it.
4. The new state has clear ownership, mutation/undo semantics, migration,
   snapshot validation, and deletion behavior.
