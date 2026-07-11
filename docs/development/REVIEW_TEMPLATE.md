# Independent Review Template

Review the diff and the surrounding implementation before changing files. Use
the root [AGENTS.md](../../AGENTS.md), the task brief, plan, and acceptance
criteria. Report no blocking findings when that is the evidence; do not invent
issues for coverage.

## Required checks

- Acceptance criteria and non-goals match the actual diff.
- Logic and regression risk, especially AppState mutation coordination and
  task completion, minimum action, and undo.
- State synchronization, stale/invalid skill or stage selection, and empty
  versus stale derived snapshots.
- Lifecycle and async safety across startup, dispose, background flush, dialog,
  and bottom-sheet contexts.
- Persistence safety: snapshot/manifest commit ordering, failed-load write
  gating, legacy compatibility, and authoritative empty collections when the
  task touches storage.
- Recurring/date/week-boundary and priority rules when the task touches them;
  avoid duplicated date or ordering rules.
- Mobile/narrow and desktop behavior, including keyboard/pointer behavior,
  reduced motion, semantics, and text scale when UI changes.
- Tests cover new paths and relevant boundaries; no assertions were weakened.
- Diff contains no unnecessary scope expansion, dependency changes, or stale
  documentation.

## Findings

Use one block per finding:

```text
Severity: blocker | high | medium | low
Confidence: high | medium | low
File/area:
Problem:
Reproduction scenario:
Why it matters:
Recommended fix:
```

Low-confidence observations must say what evidence is missing. If there are no
blocking findings, state that explicitly and list residual test or manual-QA
gaps separately.
