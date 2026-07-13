# Execution Intervention Map

## Evidence labels

The intervention classes below combine **product principles**, established UX
patterns, and **product hypotheses**. They are not clinical prescriptions and
must be validated with willing users.

## START - cannot begin

| Intervention | Problem and mechanism | Ideal moment | UX and MVP fit | Harm / safer alternative |
| --- | --- | --- | --- | --- |
| Explicit Next Action | Ambiguity blocks initiation; name one physical verb and object. | App open or focus selection. | Surface one existing active task/minimum action; MVP-ready as presentation. | Wrong suggestion can feel controlling; show "choose another". |
| Boot Quest | Entry friction is high; complete a tiny loop: open context, change one thing, inspect result. | User says "I cannot start" or a task has no minimum action. | Generate from existing Task + Minimum Action rather than a new type initially. | Can become performative micro-work; ask whether it helped. |
| Reduced scope | A task has no clear boundary. | Before deferring or when user marks resistance. | Offer "make smaller" and preserve original task. | Shrinking can hide a genuine blocker; offer blocker capture. |
| Context opening | Working memory is occupied by reconstruction. | Returning to a focused project. | Open linked artifact/instructions later; MVP can show task, stage, and latest result. | External integrations can overreach; begin with user-entered context. |
| Capacity choice | A full plan exceeds current energy. | Explicit low-capacity entry. | Optional "small / normal / deep" mode, initially presentation-only. | Avoid assumptions; never infer health or energy automatically. |

## CONTINUE - began but lost momentum

| Intervention | Problem and mechanism | Ideal moment | UX and MVP fit | Harm / safer alternative |
| --- | --- | --- | --- | --- |
| Quest Chain | A project lacks visible local sequence. | After first concrete task exists. | Derived ordered view of linked tasks/stages before a new entity. | False sequence can mislead; allow manual adjustment later. |
| Save Point | Context decays between sessions; record stop, result, blocker, next move. | End, pause, or interruption. | Needs a deliberate persistence decision; not first schema change. | Form burden; offer one-tap defaults and optional detail. |
| Blocker capture | A stuck task may be unknown rather than too large. | User pauses or marks resistance. | Short "what is blocking this?" prompt. | Do not turn every pause into a questionnaire. |
| Observable checkpoint | Work feels endless without a finished cycle. | During long tasks. | Task split or proof prompt. | Avoid surveillance; no timer-based nagging. |

## FINISH - cannot define enough

| Intervention | Problem and mechanism | Ideal moment | UX and MVP fit | Harm / safer alternative |
| --- | --- | --- | --- | --- |
| Definition of Done | Ambiguity and perfectionism extend scope. | Task/project creation or when user cannot finish. | Start as optional structured prompt; later requires model decision. | Rigid definitions can block creative work; editable and "good enough" wording. |
| Finish Quest | Closure needs a bounded final action. | Final stage or near-complete task. | Presentation over existing task/stage initially. | Premature closure; user chooses acceptance. |
| Park improvements | Future ideas hijack completion. | Before shipping or closing. | A later parking-lot feature; defer. | Parking can become backlog pressure; hide by default. |
| Final review | Make result and next maintenance visible. | Completion. | Reuse Review/history language. | Do not require reflection to count completion. |

## RETURN - resume after interruption

| Intervention | Problem and mechanism | Ideal moment | UX and MVP fit | Harm / safer alternative |
| --- | --- | --- | --- | --- |
| Return summary | Stale context makes restarting costly. | First open after absence. | Derived summary from existing task/stage/history is a low-risk prototype. | Too much stale data overwhelms; show one primary thread. |
| Save Point | Explicitly preserves where and why work stopped. | User intentionally pauses. | Requires future persistence design. | Can create an obligation; phrasing must permit a different next step. |
| Journey framing | Avoid all-or-nothing streak loss. | After inactivity. | Reframe history/review without changing recurrence rules initially. | Do not minimise real deadlines; allow practical reminders separately. |
| Anti-backlog mode | Noise makes resumption harder. | Return or low-capacity mode. | Hide non-relevant items temporarily in presentation. | Hidden work must remain discoverable and reversible. |

## Resistance: recommended conceptual role

**Recommendation - product hypothesis:** Resistance should begin as a voluntary
user signal that opens an intervention mode, not as a Task type or diagnosis.

| Approach | Benefit | Cost / risk | Recommendation |
| --- | --- | --- | --- |
| Separate Quest type | Explicit analytics and styling. | Adds domain branching, schema, and stigma risk. | Do not start here. |
| Temporary Task state | Can persist a current mode. | Risks overwriting task semantics and completion state. | Consider only after validation. |
| Intervention mode | Offers reduce-scope, Boot Quest, blocker, stopping point, or Save Point around an existing task. | Needs careful non-intrusive UX. | Recommended first approach. |
| User signal only | Lowest data risk and maximally voluntary. | Weak continuity between sessions. | Good MVP implementation shape. |

## Delivery matrix

This completes the implementation assessment for every intervention above.
`No AI` means the intervention is useful and testable without AI.

| Intervention | Complexity | Data-model impact | AI required | Test without AI | MVP decision |
| --- | --- | --- | --- | --- | --- |
| Explicit Next Action | Small | Derived selector only | No | Yes: clarity, action switch, stale IDs | Include early. |
| Boot Quest | Small-medium | None if generated from Minimum Action | No | Yes: entry cycle and observable result | Include early with Next Action. |
| Reduced scope | Small | None initially | No | Yes: task resize / new minimum action | Include through Resistance menu. |
| Context opening | Medium | Optional links only later | No | Yes: return summary and open-context action | Defer external integrations. |
| Capacity choice | Small | Presentation preference only | No | Yes: voluntary mode selection | Experimental after core entry. |
| Quest Chain | Medium | Derived first; durable order later | No | Yes: sequence comprehension | Defer until Next Action evidence. |
| Save Point | Medium prototype, large durable form | Dedicated state only after validation | No | Yes: derived return card | Prototype second; persistence later. |
| Blocker capture | Small | Optional note later | No | Yes: voluntary prompt and task resumption | Experimental within Resistance. |
| Observable checkpoint | Small-medium | None first | No | Yes: task split/result note | Include only if long tasks remain opaque. |
| Definition of Done | Medium | Description first; field later | No | Yes: finish diary and optional prompt | Experimental after entry/return. |
| Finish Quest | Small-medium | Presentation over existing task/stage | No | Yes: closure flow | Defer with Definition of Done. |
| Park improvements | Medium | New relation/tag likely later | No | Yes: temporary presentation bucket | Defer. |
| Final review | Small | Existing review model | No | Yes: optional review completion | Retain as supporting. |
| Return summary | Small-medium | Derived | No | Yes: 1/3/7-day return test | Include second. |
| Journey framing | Small | Presentation over history | No | Yes: copy/interview audit | Include with return prototype. |
| Anti-backlog mode | Small-medium | Presentation filter | No | Yes: reversible filter use | Defer until return validation. |

## Validation boundary

No intervention requires AI to be useful. AI could later propose decomposition
or summaries only with explicit user control, editable output, and a non-AI
fallback. Test every intervention without AI first.
