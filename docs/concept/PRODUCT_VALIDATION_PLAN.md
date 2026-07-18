# Product Validation Plan

## What to validate

Validate whether RPG To-Do lowers the cost of action and return. Do not use
task count, XP gained, or app opens alone as proof of value.

| Question | Evidence to collect | Success signal | Failure signal |
| --- | --- | --- | --- |
| Does Next Action help START? | Timed self-test, action diary, short clarity prompt. | Shorter open-to-meaningful-action time and reported clarity. | Users ignore, dispute, or feel constrained by it. |
| Does Return Context help RETURN? | Return after 1, 3, and 7 days in diary studies. | User resumes without rereading long backlog. | Summary is stale, guilt-inducing, or creates extra work. |
| Does Boot Entry help? | Voluntary use and immediate outcome note. | A concrete entry action follows more often than a dismissal. | It becomes a ritual with no real result. |
| Does Definition of Done help FINISH? | Completion stories and parked-improvement rate. | Users finish more intentionally without feeling rushed. | Users feel boxed in or add unnecessary setup. |
| Does Side-Quest framing help focus? | User interview and focus-change rationale. | Users can distinguish support work without shame. | Labels devalue legitimate exploration. |

## Methods before analytics

1. **Founder self-testing:** use real projects, record intention, next action,
   result, stopping point, and return effort.
2. **Diary study:** a small voluntary group records short before/after notes for
   one to two weeks; no diagnostic screening required.
3. **Semi-structured interviews:** ask what was easier, harder, confusing, or
   emotionally pressuring.
4. **Manual debug events:** only in local debug builds and with no production
   user data export; use to inspect flow ordering, not user worth.
5. **Optional privacy-respecting analytics later:** require a separate consent,
   data-retention, and threat-model decision.

## Suggested measures

- Time from app open to a user-defined meaningful action.
- Share of focused contexts with a clear Next Action.
- Share of sessions with an observable result or intentional Save Point.
- Ability to resume after one, three, and seven days.
- Frequency of voluntary task resizing and whether it helps.
- Side-Quest activity relative to user-declared Main Quest movement.
- Voluntary use and usefulness of return summaries.
- User-reported clarity, activation difficulty, pressure, and shame.
- Whether the app itself becomes another planning burden.

## Next Action Lens MVP protocol

Before making the override or Boot Entry durable, run a small voluntary
self-test or diary pass with real work. For each use, note:

1. whether the shown action was understood within ten seconds;
2. whether the user accepted it, chose another action, or ignored it;
3. whether Boot Entry led to a concrete change rather than only checking boxes;
4. whether the lack of restart persistence was harmful;
5. whether the copy felt calm, optional, and non-judgmental.

Do not treat Boot Entry opens, task count, XP, or app time as success by
themselves. The relevant evidence is a lower activation cost followed by a
real-world action, or clear evidence that the intervention should be changed
or removed.

## Return Context prototype protocol

Use the copyable
[Return Context validation diary](RETURN_CONTEXT_VALIDATION_DIARY.md) after
real pauses of approximately one, three, and seven days. For each use, verify
within ten seconds whether the prior thread is credible, whether any shown
result is useful rather than misleading, and whether Continue, another step,
or dismissal led to less backlog reconstruction.

The prototype is derived and its dismissal is intentionally session-only.
Record whether restart loss is actually harmful before proposing a durable
Save Point. Do not count card impressions, opens, XP, app time, or checked Boot
steps as evidence of return value.

## Ethics and interpretation

- Do not infer diagnosis, health, capacity, or compliance from usage.
- A user may prefer planning, exploration, or rest; lower task count is not
  necessarily failure.
- Compare outcomes with the user's stated intention, not an ideal daily-use
  target.
- Treat negative feedback and non-use as valid evidence against a hypothesis.
