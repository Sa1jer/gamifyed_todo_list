# Codex Task Workflow

This repository uses one lifecycle for non-trivial work. The root
[AGENTS.md](../../AGENTS.md) is the compact operational contract; this document
contains the detailed hand-off rules.

| Stage | Goal | Allowed | Prohibited | Output |
| --- | --- | --- | --- | --- |
| Brief | Turn a request into observable outcomes. | Clarify product impact, constraints, evidence, and acceptance criteria. | Assuming an unrequested product decision. | Filled task brief. |
| Explore | Understand the existing system. | Read docs, code, tests, data flow, and current diff. | Editing product or test code. | File map, risks, open questions. |
| Plan | Define the smallest safe change. | Select files, tests, rollback notes, and validation. | Editing product code or concealing uncertainty. | Approved implementation plan. |
| Implement | Make the agreed change. | Focused edits, focused tests, targeted debugging. | Scope creep, unrelated refactors, weakening tests. | Working diff and tests. |
| Review | Independently look for defects. | Read the diff and surrounding code; compare with acceptance criteria. | Editing before findings are written; inventing findings for quantity. | Severity-ranked findings or explicit no-blocker result. |
| Fix | Resolve confirmed review findings. | Minimal fixes and tests for each confirmed finding. | New features or unrelated cleanup. | Finding-by-finding disposition. |
| Verify | Prove the requested outcome. | Run validation and evaluate every criterion independently. | Treating the implementer's summary as evidence. | Acceptance record. |
| Accept | Make the hand-off honest and usable. | Report evidence, skipped checks, risks, and manual QA. | Claiming unrun checks or hiding limitations. | Completion report. |

## Independent review

Run Review in a new Codex session when possible, or as an isolated pass that
does not rely on the implementer's self-assessment. The reviewer first writes
findings and evidence; only the Fix stage edits code. Each finding needs a
severity, confidence, and reproduction scenario. Mark low-confidence concerns
as assumptions, not defects.

## Repository-specific review focus

Prioritize AppState mutation coordination, task completion/minimum-action/undo,
snapshot and legacy Hive recovery, startup/dispose/background races, stale
selection IDs, empty committed snapshots, recurrence and calendar boundaries,
and mobile/desktop composition differences. See
[REVIEW_TEMPLATE.md](REVIEW_TEMPLATE.md) for the full checklist.

## Backlog discipline

Update [TODO.md](../../TODO.md) after meaningful product, architecture, or
design work. Review discoveries outside the approved scope become focused
follow-ups with evidence; they are not silently fixed in the current batch.
