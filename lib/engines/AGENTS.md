## Engine rules

Read the root [AGENTS.md](../../AGENTS.md) and
[docs/APPSTATE_MAP.md](../../docs/APPSTATE_MAP.md) first.

- Keep engine APIs pure and deterministic where practical. Pass `now` into
  wall-clock logic instead of reading it deep inside a rule.
- Test day, week, month, recurrence, priority, empty-input, and identifier
  boundary cases. Recurring catch-up must not become a linear loop across long
  gaps.
- Keep domain rules in one engine; widgets and AppState orchestrate them but do
  not reimplement them.
- Do not alter XP, goal, RoadMap, recurring, reward, or SMARTER behavior without
  an explicit product requirement and regression coverage.
