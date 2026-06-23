## External cybersecurity skills

A local cybersecurity skill library is available at:

`B:\My Projects\AI-Skills\Anthropic-Cybersecurity-Skills`

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

Recommended lookup path:

`/Users/saijer/VSCode Projects/AI Skills/Anthropic-Cybersecurity-Skills\skills`

When using a skill, mention which skill file was consulted and summarize the relevant checklist before proposing code changes.

## Local refactoring, testing, and hardening skills

Local Codex skills are available at:

`/Users/saijer/VSCode Projects/AI Skills/RPGTodo-Refactoring-Skills`

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

Current known priority:

Fix and audit the achievement dialog crash caused by unsafe provider/context access inside dialog builder contexts.
