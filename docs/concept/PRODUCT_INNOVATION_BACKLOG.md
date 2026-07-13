# Product Innovation Backlog

## Ranking method

Scores are directional, not promises: impact, evidence strength, complexity,
architecture risk, and differentiation are `low`, `medium`, or `high`.
Evidence labels distinguish research-supported patterns, established UX
patterns, product hypotheses, and speculative experiments.

Each table row is an innovation card in compact form: its interaction describes
the user story, mechanism, and example; the impact column includes expected
value, complexity, and evidence. Confidence is intentionally lower for product
hypotheses and speculative experiments than for established UX patterns.

| Rank | Innovation | User problem and interaction | Architecture / storage impact | UX and misuse risk | MVP | Value / evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Next Action Lens** | User opens a project and sees one concrete physical move with "choose another". | Derived from existing task, minimum action, stage, review focus, and ordering. No schema. | A wrong default can feel prescriptive; always expose alternatives. | One action card with source context. | High impact, low complexity, established UX pattern. |
| 2 | **Return Card** | "You paused here: result, blocker, first re-entry." | Prototype derives from task/stage/history; durable Save Point later. | Stale summaries can mislead; show timestamp and edit/ignore action. | Last relevant context summary. | High impact, medium complexity, product hypothesis. |
| 3 | **Boot Sequence** | "I cannot start" opens: context, one tiny change, inspect result. | Generated mode around existing Task/Minimum Action. No schema first. | Can become ritual without work; ask for one observable change. | Three optional short prompts. | High impact, low risk, established behavioral pattern. |
| 4 | **Resistance Signal** | User explicitly says a task feels avoided; app offers choices, not a diagnosis. | Ephemeral UI state first. | Stigma, over-prompting, or pseudo-therapy; entirely voluntary. | Menu: shrink, clarify, blocker, stop point. | High fit, low complexity, product hypothesis. |
| 5 | **Definition of Done Prompt** | User names an acceptable boundary before endless polish. | Start in description presentation; later optional field only if validated. | Can be rigid for exploratory work; editable "good enough" contract. | One optional sentence. | High FINISH value, medium complexity, established UX pattern. |
| 6 | **Proof of Progress Prompt** | On completion, user answers "what changed in the real world?". | Transient first; persistence only after validation. | Reflection can delay closure; skippable and not required for XP. | Optional one-line prompt. | Medium-high value, medium risk, product hypothesis. |
| 7 | **Quest Chain View** | Project work becomes a visible sequence of observable checkpoints. | Derived from current ordered tasks and stage links. | False ordering / complexity; no forced chain creation. | Read-only chain with next item. | Medium-high value, medium complexity, product hypothesis. |
| 8 | **Side-Quest Parking** | Useful ideas/research stop hijacking main movement. | Derived focus comparison; later tag/relationship if needed. | Labels may shame exploration; use neutral copy and user control. | "Park for later" presentation bucket. | Medium value, medium risk, product hypothesis. |
| 9 | **Capacity Modes** | Low energy should still have a valid entry without false normality. | Presentation preference; no health inference. | Mode labels can become self-judgment; user selects manually. | Small / normal / deep choices. | Medium value, low complexity, inclusive UX pattern. |
| 10 | **Anti-Backlog Mode** | Returning user sees only current context, not accumulated noise. | Presentation filter over existing tasks. | Hidden tasks can feel lost; reversible banner and search. | Temporary "show current only". | Medium value, low risk, product hypothesis. |
| 11 | **Research Drift Reflection** | User notices activity without a completed result. | Derived from voluntary check-in, not surveillance. | Can shame research; phrase as question and let user dismiss. | Manual "did this move the result?" check. | Medium value, medium risk, product hypothesis. |
| 12 | **Gentle body-doubling integration** | Some users benefit from a co-working cue. | External integration / privacy boundary. | High privacy and dependency risk. | Do not build now. | Potential value, speculative experiment. |
| 13 | **AI decomposition with control** | User does not know the next step. | New service, consent, privacy, failure handling. | Incorrect advice, dependency, sensitive data. | Do not build before non-AI flow. | Differentiating but speculative. |
| 14 | **Ambient focus / novelty modes** | User wants a different sensory or stimulation level. | Settings/presentation only at first. | Sensory assumptions and feature bloat. | Defer until demand evidence. | Low-medium value, speculative. |

## High-impact recommendations

### Next Action Lens

- **Why it may work:** it reduces choice and translation from abstract goal to
  physical behavior.
- **Where it may fail:** multiple equally valid actions or tasks requiring
  external context can make a single default misleading.
- **Who it may not suit:** users who intentionally rotate among several active
  areas in one session.
- **Safer alternative:** show a compact shortlist without ranking language.
- **Validation:** time-to-first-action, voluntary action switching, and clarity
  rating after use.

### Return Card / Save Point prototype

- **Why it may work:** it reduces context reconstruction after interruption.
- **Where it may fail:** automatic summaries do not know the user's true
  blocker or next intention.
- **Who it may not suit:** users who prefer a clean restart or frequently change
  direction.
- **Safer alternative:** derived card with "start fresh" and "hide" actions.
- **Validation:** return-after-pause task completion and user-reported effort to
  remember what was next.

### Resistance Signal

- **Why it may work:** it gives the user a non-moralised path when task
  avoidance is already visible to them.
- **Where it may fail:** an intrusive prompt may amplify attention to friction.
- **Who it may not suit:** people who do not want emotional framing in a task
  tool.
- **Safer alternative:** neutral action label such as "Нужен другой вход".
- **Validation:** voluntary usage, dismissal rate, and whether users make a
  smaller concrete move afterward.

## Explicitly not prioritised

- Any feature that requires users to classify every task as Main, Side,
  Resistance, or Boot work before beginning.
- AI, body-doubling, ambient audio, or energy inference as a prerequisite to
  the core loop.
- More rewards, random chests, or streak pressure as a substitute for clarity.
