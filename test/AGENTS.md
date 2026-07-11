## Test rules

Read the root [AGENTS.md](../AGENTS.md) and
[docs/development/REVIEW_TEMPLATE.md](../docs/development/REVIEW_TEMPLATE.md).

- A regression test should reproduce the defect before the fix whenever
  practical; never weaken an assertion just to make CI pass.
- Add the corresponding edge or boundary case for date, ID, lifecycle, storage,
  selection, or layout regressions.
- Keep tests deterministic: inject time where the production API allows it and
  avoid arbitrary delays.
- Exercise mobile and desktop only when the changed surface is shared; use
  focused tests rather than broad unrelated rewrites.
