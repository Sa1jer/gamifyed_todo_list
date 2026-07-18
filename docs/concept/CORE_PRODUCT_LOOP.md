# Core Product Loop Options

## Current loop

**Repository fact:** the current loop is approximately:

```text
Skill -> Goal -> RoadMap / Stage -> Task -> Minimum Action -> XP -> Review / Nudge
```

It already supports small entry actions and later reflection. The derived
Return Context prototype now makes one evidence-backed thread primary after a
pause, but there is still no user-authored durable Save Point or structured
observable outcome.

## Option A - Quest-first

```text
Chosen Skill -> explicit Next Action -> complete a Quest -> see result -> choose next Quest
```

| Strengths | Weaknesses | Architecture effect | Risks |
| --- | --- | --- | --- |
| Low implementation cost; uses active Tasks and Minimum Actions. | Weak support for long sessions and return after pause. | Mostly presentation and selector logic. | Can remain a conventional to-do list with XP. |

## Option B - Session-first

```text
Intention -> Boot / entry session -> bounded checkpoint -> Proof of Progress -> Save Point -> return
```

| Strengths | Weaknesses | Architecture effect | Risks |
| --- | --- | --- | --- |
| Directly addresses activation, continuation, and return. | Session language may not suit recurring or tiny tasks. | Starts presentation-only; durable Save Points eventually need storage design. | Can become a timer/surveillance product if over-instrumented. |

## Option C - Journey-first

```text
Goal -> Journey -> active chapter / stage -> current Quest -> review -> gentle return
```

| Strengths | Weaknesses | Architecture effect | Risks |
| --- | --- | --- | --- |
| Uses existing Goal, RoadMap, history, and reviews; removes streak loss framing. | Can make planning and narrative more prominent than action. | Mostly copy/presentation at first. | Can become an overcomplicated game or a vague self-development journal. |

## Option D - Recommended hybrid: Action inside a Journey

```text
Intention / context
  -> one Main Quest boundary
  -> one explicit Next Action or Boot sequence
  -> completed observable work cycle
  -> Proof of Progress or Save Point
  -> next action or low-pressure return
```

### Why this is recommended

**Inference:** RPG To-Do already has the ingredients for this loop. Skill and
RoadMap provide long-term context; Task and Minimum Action provide action;
history/review provide evidence. The missing emphasis is a deliberately chosen
next action and a reliable return context.

### Existing architecture fit

- **Skill** stays a stable context, not necessarily a newly renamed model.
- **RoadMap** remains an optional path and should not block starting.
- **Task** remains the source of completion, XP, undo, recurring, and storage
  semantics.
- **Minimum Action** becomes the first existing tool for Boot mode.
- **CourseNudgeEngine** can eventually inform an optional next-action chooser,
  but must not become a coercive ranking system.
- **Review** can become a deliberate change-of-direction checkpoint instead of
  a periodic productivity score.

### Mobile implications

Mobile should open to one context and one next useful move, with a visible way
to switch context. Project planning, RoadMap, rewards, and statistics should
remain available but should not be prerequisites to beginning.

### XP and achievement implication

No XP rule changes are proposed. The future visual hierarchy should attach XP
to a completed real work cycle and avoid presenting XP selection as the first
decision in simple capture.

### Validation signal

The hybrid succeeds if users reach a meaningful action faster, can return after
a pause with less reconstruction, and report more clarity without increasing
planning burden. It fails if users feel compelled to classify every task or
perform extra reflection before working.

## Implemented boundary - START plus derived RETURN prototype

The implemented first slice covers only the `Next Action -> Boot sequence`
portion of the hybrid. On mobile Act, one derived action is visible before the
full Skill list. The user can choose another valid Skill quest, open its normal
task context, or enter a temporary Boot loop when starting feels difficult.

Boot completion acknowledges entry without pretending the parent Quest is done:
it grants no XP and does not update Minimum Action, Task completion, RoadMap,
Goal, history, rewards, or statistics. `Proof of Progress` and `Save Point`
remain deliberately outside this slice.

Return Context adds the reversible RETURN experiment. After a meaningful pause,
it derives one prior normal-Skill thread from completion/review evidence and
reuses Next Action for the current valid move. Its dismissal is session-only,
it performs no mutation while rendering, and Continue only opens existing
focus after revalidation. This is not a Save Point and does not prove durable
state is valuable.
