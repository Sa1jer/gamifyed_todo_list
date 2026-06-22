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