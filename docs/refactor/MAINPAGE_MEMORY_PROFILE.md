# MainPage Runtime Memory Profile

Last updated: 2026-07-18

## Measurement Contract

Memory samples are comparable only when all of the following are recorded:

1. exact git revision and Flutter mode;
2. executable path and PID of the visible application process;
3. the same RSS command and sampling interval;
4. confirmation that the Flutter window is open and interactive;
5. the same navigation/dialog scenario;
6. DevTools heap snapshots before and after returning to idle.

The historical samples `846944 -> 846976 KB` and `22688 -> 23264 KB` do not
meet that contract. Their PID/window/scenario evidence differs, so they cannot
support a before/after memory claim. They only show that the sampled processes
did not exhibit obvious short-interval linear growth.

## Required Interactive Scenario

Using `flutter run -d macos --profile`, record the visible application PID,
then perform ten cycles of:

1. switch between `Сейчас`, `Карта`, `Трофеи`, and `Статистика`;
2. select several Skills and return to overview;
3. open and close RoadMap, Weekly Analytics, Progress Hub, profile, Add Skill,
   and Add Quest surfaces;
4. expand and collapse Inbox;
5. toggle dark/light theme;
6. return to `Сейчас` and wait for pending animations/saves to settle.

Capture DevTools heap snapshots before the first cycle and after the final idle
period. Compare retained routes, controllers, listeners, `ui.Image` objects,
decoded image memory, analytics snapshots and external memory. Do not force GC
or clear caches to manufacture a lower result.

## Current Static Evidence

- MainPage shell persistence/profile/tutorial changes no longer reconstruct the
  workspace tree.
- Theme transition ownership disposes a captured `ui.Image` even when the root
  widget unmounts while capture is in flight.
- Profile image decoding remains bounded to rendered dimensions.
- No runtime memory reduction is claimed without the interactive scenario.

## 2026-07-18 Profile Run

- base revision: `49109c0` plus the uncommitted MainPage observation batch;
- command: `flutter run -d macos --profile`;
- executable:
  `build/macos/Build/Products/Profile/todo_list_app.app/Contents/MacOS/todo_list_app`;
- PID: `6152` (one matching application process);
- the Flutter window was activated and confirmed as the frontmost
  `todo_list_app` process;
- RSS samples from that same PID were `89648 KB`, `104272 KB`, then
  `60688 KB` over approximately nine minutes; sampled CPU was `0.0%`.

The samples are non-monotonic and show no idle runaway growth in this run. They
do not demonstrate a memory reduction. macOS Accessibility access for scripted
window interaction was unavailable, so the ten navigation/dialog cycles and
DevTools before/after heap snapshots were not performed. Those checks remain
required before making route, controller, or post-GC retention claims.
