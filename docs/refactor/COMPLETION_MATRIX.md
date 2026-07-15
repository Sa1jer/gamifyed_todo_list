# Refactor Completion Matrix

Last updated: 2026-07-15

| Criterion | Status | Evidence / limitation |
|---|---|---|
| Weekly analytics does not retain AppState/live models | Confirmed | Scalar `WeeklyAnalyticsViewData` and direct tests. |
| Base analytics is immutable by value | Confirmed | Scalar history records, unmodifiable collections and deterministic ties. |
| Cache cannot miss a relevant public notification | Confirmed | Conservative invalidation in AppState notification boundary. |
| Completion and reward domains extracted | Confirmed | Dedicated coordinators plus direct regression tests. |
| At least two further AppState responsibilities extracted | Confirmed | Skill/goal and review/session coordinators. |
| AppState materially smaller | Confirmed | About 3405 -> 2591 lines. |
| Persistence scheduling extracted | Confirmed | `SaveScheduler` with debounce/single-flight/trailing/failure tests. |
| Storage helper responsibilities split | Confirmed | Store, codec and migration policy; StorageService remains compatibility facade. |
| Models declarations split | Confirmed | Eight modules and unchanged compatibility barrel/schema. |
| Desktop workspace fully modular/no `part` | Not complete | Right rail is an ordinary module, but the 2240-line shell remains a `part`. P1 follow-up. |
| Weekly Analytics fully decomposed | Partially confirmed | Scalar read data and repeated UI sections extracted; 1571-line shell remains. P1 follow-up. |
| Shared catch-all reduced | Confirmed with follow-up | Cohesive modules extracted; compatibility barrel still contains legacy categories. |
| Task form has independent lifecycle owner | Confirmed | Expanded `TaskFormController`; shell remains sizeable. |
| Today/Tasks repeated build calculations reduced | Confirmed | Deterministic prepared view-data objects and tests. |
| Root rebuild selector migration | Confirmed at shell boundary | `InheritedNotifier` preserves feature updates; `AppStateSelector` prevents unrelated domain mutations from rebuilding the root shell. Feature-level broad observation remains a P1 profile target. |
| Toast geometry suite green without product revert | Confirmed | Stale hard-coded test value replaced by production safe-region contract. |
| Architecture drift gate exists | Confirmed | `tool/architecture_audit.dart`, run by `tool/verify.dart`. |
| Storage schema/product semantics unchanged | Confirmed | No type/key/formula changes in diff. |
| Runtime memory improvement measured | Partially verified | Profile idle RSS was 846944 -> 846976 KB; interactive heap/rebuild scenarios remain. |
| Full validation | Confirmed | Non-mutating format, analyze, architecture audit, 416 tests, diff check and macOS release build passed. |
