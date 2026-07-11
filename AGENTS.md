## External cybersecurity skills

An optional local cybersecurity skill library may be configured outside this
repository.

Use it only for defensive security review, secure coding, threat modeling, vulnerability triage, dependency review, and application hardening.

When a task is security-related:

1. First inspect the repository normally.
2. Then search the external skill library by skill name, domain, tags, and frontmatter.
3. Prefer loading only the most relevant `SKILL.md` files, not the whole library.
4. Use the skill workflow as guidance, not as automatic truth.
5. Do not perform offensive actions against real third-party targets.
6. Do not generate exploit instructions, credential theft steps, persistence payloads, evasion payloads, or malware.
7. For this Flutter app, prefer defensive use cases:
   - threat modeling
   - auth/storage/privacy review
   - dependency/security config review
   - local data protection
   - debug/admin panel hardening
   - release build hardening
   - secret leakage checks
   - unsafe logging checks

When a relevant library is unavailable, continue with the repository rules and
state that limitation. When using a skill, mention which skill file was
consulted and summarize the relevant checklist before proposing code changes.

## Local refactoring, testing, and hardening skills

Optional local Codex skills may be installed outside this repository. If they
are unavailable, follow the equivalent repository workflow and state that
limitation.

Use these skills when relevant:

- `flutter-bug-audit`: crash audits, null-safety bugs, lifecycle bugs, provider/context problems, subtle regressions, release-sensitive bug patterns.
- `widget-dialog-safety`: dialogs, bottom sheets, overlays, provider reads, inherited widget context, navigation/context safety.
- `appstate-decomposition`: before extracting logic from AppState, creating engines, or moving business logic out of widgets.
- `refactor-batch-protocol`: before any cleanup/refactoring/architecture batch.
- `release-mobile-hardening`: before release, debug admin changes, local storage changes, notification changes, or security-sensitive code.
- `flutter-architecture-testing`: before UI/navigation/form/testing refactors.
- `future-cloud-boundary`: before model/storage/AppState changes that may affect future cloud sync/auth/backup.

External references:

- OWASP MASVS / MASTG: defensive mobile security, privacy, release hardening, and mobile testing checklists.
- `firebase/flutterfire`: future Firebase/auth/sync/notification boundaries only; do not implement Firebase unless explicitly requested.
- `VeryGoodOpenSource/very_good_cli`: architecture discipline, testing, quality gates, release discipline.
- `flutter/samples`: Flutter UI, navigation, forms, Material 3, testing, and sample patterns.

Project rules:

- Do not rewrite the whole project in one batch.
- Do not mix bug fixes with new features.
- Do not mix refactoring with product redesign.
- Prefer tests before risky extraction.
- Keep behavior unchanged unless explicitly requested.
- Use external references as checklists and inspiration, not as code to copy.
- Never import large external code into this repo without approval.
- Run or request:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test -r expanded --timeout 30s`

## RPG To-Do repository workflow

### Product context

RPG To-Do turns small actions into growth. The core loop is `Навык -> Цель ->
RoadMap -> Этап -> Квест -> Минимальный шаг -> XP -> Рост`; use
[README.md](README.md) as the product source of truth. The main surfaces are
`Сейчас`, `План`, `Карта`, and `Рост`. SMARTER is a soft guidance layer, not a
mandatory wizard; keep advanced fields out of the primary action flow unless a
task explicitly changes that decision. Preserve action-first narrow/mobile UX,
lightweight priority guidance, and RoadMap as a path rather than a free-form
editor. See [docs/SMARTER_ROADMAP.md](docs/SMARTER_ROADMAP.md) and
[docs/MOBILE_UX_UI_AUDIT.md](docs/MOBILE_UX_UI_AUDIT.md).

### Architecture context

- [lib/main.dart](lib/main.dart) owns application startup, theme wiring, and
  lifecycle handoff.
- [lib/app_state.dart](lib/app_state.dart) is the runtime facade and mutation
  coordinator. Completion, minimum-action, undo, selection, and save flows are
  high-risk; do not broadly split or bypass it without a separate approved
  batch.
- [lib/models.dart](lib/models.dart) contains persisted domain entities.
  [lib/engines](lib/engines) contains pure domain rules where possible; do not
  duplicate those rules in widgets or AppState.
- [lib/storage_service.dart](lib/storage_service.dart) and
  [lib/storage_snapshot.dart](lib/storage_snapshot.dart) own Hive, snapshot /
  manifest recovery, and legacy compatibility. Read
  [docs/STORAGE_SNAPSHOT_MANIFEST.md](docs/STORAGE_SNAPSHOT_MANIFEST.md) before
  changing persistence or startup lifecycle behavior.
- [lib/widgets](lib/widgets) is presentation; desktop and mobile deliberately
  use different compositions. [test](test) is the regression suite, and
  [docs/APPSTATE_MAP.md](docs/APPSTATE_MAP.md) is the current architecture map.

Do not change Hive schema, snapshot semantics, XP / goal / RoadMap / recurring
rules, or the large AppState boundary without explicit approval. Empty committed
collections are authoritative, stale selections must be rejected, and failed
startup loads must never be followed by destructive saves.

### Mandatory workflow

For every non-trivial task:

1. Read the brief, related documentation, code, and tests.
2. Explore dependencies, current data flow, risks, edge cases, and open
   questions before editing.
3. Write a scoped plan before changes, then implement only that agreed scope.
4. Add or update focused tests; for a bug, reproduce it first where practical.
5. Run validation, inspect the final diff, and independently review it against
   the acceptance criteria.
6. Record unresolved findings as follow-ups instead of silently expanding scope.
7. Update affected documentation and [TODO.md](TODO.md) after meaningful
   product, architecture, or design work.

The full lifecycle is [Brief -> Explore -> Plan -> Implement -> Review -> Fix
-> Verify -> Accept](docs/development/TASK_WORKFLOW.md). Use the reusable
procedures in [docs/development/prompts](docs/development/prompts) and the
templates in [docs/development](docs/development).

### Scope discipline

- Do not perform adjacent refactors, dependency upgrades, or public behavior
  changes without an acceptance criterion.
- Do not delete code because it looks obsolete without evidence of reachability
  and callers.
- Do not hide failures, weaken assertions, or mark work complete when a check
  was not run. State facts separately from assumptions.
- Preserve existing tests; add boundary coverage when fixing a boundary bug.
- New review findings outside scope become evidence-backed backlog items, not
  automatic fixes.

### Validation

Routine validation is:

```bash
dart format lib test
flutter analyze
flutter test -r expanded --timeout 30s
git diff --check
```

Use `dart run tool/verify.dart` for the non-mutating local equivalent. Run
[docs/ANDROID_RELEASE_CHECKLIST.md](docs/ANDROID_RELEASE_CHECKLIST.md)
for Android release work: debug APK builds are appropriate for Android changes;
signed APK/AAB builds require the private signing configuration. Run the native
desktop build only on the relevant host. This repository currently has no
tracked generated Dart output, so generator checks are required only if a task
introduces or changes generated code.

### Completion report

End each task with: changed files and behavior; acceptance criteria status;
commands run and results; checks not run and why; remaining risks or
assumptions; and the required manual QA, if any.
