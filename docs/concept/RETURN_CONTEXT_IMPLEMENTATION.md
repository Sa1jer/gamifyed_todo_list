# Return Context: derived prototype

## Product boundary

`Return Context` is a derived presentation summary that helps the user
reconnect with one existing work thread after a meaningful pause. It is
recomputed from completion history, Goal reviews, current Skills, RoadMap
Stages, and the existing `NextActionResolver` output.

It is not a `Save Point`. A future Save Point would be a durable,
user-authored record of the stop point, result, blocker, next action, and an
opening cue. This prototype does not add a model, Hive field, snapshot field,
or persistence key.

`Next Action` still owns selection of one currently valid Task. Return Context
only establishes the prior Skill thread and consumes the detached order
produced by that resolver. `Boot Entry` remains a temporary entry loop around
the chosen Task and continues to grant no XP.

The intended relationship is:

```text
meaningful prior work
-> derived Return Context
-> one valid Next Action
-> optional Boot Entry
-> normal Task workflow
```

## Evidence and pause semantics

The repository does not currently persist application-open or application-
background timestamps. The prototype therefore does not claim how long the
user was absent. Its pause threshold is measured from the latest reliable work
evidence:

- a recorded normal-Skill completion;
- a meaningful Goal review.

The default threshold is one day and is an explicit resolver input in tests.
Inbox activity, navigation, theme changes, profile edits, reward claims, and
persistence events are not meaningful work evidence.

## Candidate policy

Candidate selection is deterministic:

1. The newest completion attached to an existing normal Skill is the strongest
   thread.
2. A still-valid prior Task is preferred; otherwise the first current action in
   the same Skill is taken from the existing `NextActionResolver` order.
3. A Goal review with a non-empty `nextFocus` is a weaker fallback.
4. The selected Skill is only a final hint when an older meaningful event proves
   that a pause occurred.
5. Missing Skills, missing Tasks, missing or locked Stages, and Inbox are never
   actionable targets.

The resolver result contains only scalar immutable data. It retains no
`AppState`, `Task`, `Skill`, `HistoryEntry`, `GoalReviewEntry`, or
`SkillTreeNode` references.

When the current valid Next Action is attached to an active RoadMap Stage, the
card labels it as `Текущий этап`. The prototype does not claim that this is the
exact historical stop point because completion history does not retain a
reliable Stage snapshot.

## Session behavior

The MainPage feature owner keeps only a dismissed candidate key in memory.
`Не сейчас` and `Другой шаг` hide that key for the current process and reveal
the existing Next Action Lens on mobile. A genuinely new evidence/action key
can appear in the same session. Restarting the application restores eligibility
because no dismissal is persisted.

Rendering is side-effect free. `Продолжить` revalidates the Skill and current
Next Action before selecting the existing Skill focus. It never completes a
Task or Minimum Action, awards XP, writes history, modifies Goal/RoadMap
progress, or claims a reward.

## Validation boundary

Automated tests validate selection and interaction safety, not product value.
Real one-, three-, and seven-day uses should be recorded in
[RETURN_CONTEXT_VALIDATION_DIARY.md](RETURN_CONTEXT_VALIDATION_DIARY.md).
Only evidence that restart loss is repeatedly harmful may justify a separate
durable Save Point design.
