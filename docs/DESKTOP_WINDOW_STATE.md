# Desktop Window State

Updated: 2026-08-19

## Policy

Desktop window placement is native runtime state, not RPG To-Do domain data.
It never enters Hive, snapshots, `AppState`, or `notifyListeners()`.

- A first launch, missing value, corrupt value, or invalid normal frame opens
  maximized in the usable work area. Maximized is a regular resizable desktop
  window, not macOS fullscreen or Windows borderless fullscreen.
- A later normal launch restores the last normal size and position.
- Closing while maximized restores maximized next time while retaining the
  previous normal frame for a later unmaximize action.
- A partially visible frame is clamped into its best matching display's work
  area. A frame from a disconnected display is centered on the primary work
  area while preserving a valid size.
- Window bounds are applied before the first visible Flutter frame to avoid a
  visible intermediate `1280 x 720` window.

## Platform Boundaries

### macOS

`macos/Runner/DesktopWindowPlacement.swift` owns the placement policy and stores
`normalFrame` plus `isMaximized` in `UserDefaults` under
`desktopWindowPlacement.v1`. `macos/Runner/MainFlutterWindow.swift` supplies
`NSScreen.visibleFrame`, ignores native fullscreen geometry, applies the
resolved frame before creating visible Flutter content, and persists once on
window close or application termination (`Cmd+Q`).

The pure placement/store cases live in `macos/RunnerTests/RunnerTests.swift`.

### Windows

`windows/runner/desktop_window_state.*` stores versioned native values under:

```text
HKCU\Software\RPGToDo\WindowState
```

It records signed normal bounds, maximized state, and the DPI belonging to the
normal frame. The hidden runner window is moved and sized before its Flutter
view is created; only the first rendered Flutter frame shows it. Restoration
uses monitor work areas, rescales size when display DPI changes, and validates
the restored size in 96-DPI logical units so high-to-low DPI transitions cannot
produce an unusably small window. This is restore validation, not a native
minimum-size constraint on user resizing.

No package or Dart bridge is required. Android and iOS startup are unaffected.

## Manual macOS Smoke

1. Remove only the `desktopWindowPlacement.v1` preference.
2. Launch and confirm a maximized, non-fullscreen window with no visible size
   jump.
3. Unmaximize, resize, move, close, and reopen; verify normal geometry.
4. Repeat the previous step using `Cmd+Q` instead of the red close control.
5. Maximize, close, and reopen; verify maximized state, then unmaximize and
   verify the previous normal frame.
6. If a second display is available, close there, disconnect it, and verify the
   next launch is visible on the primary display.
7. Enter and leave macOS fullscreen; confirm fullscreen itself is not restored.

To clear the preference for testing without touching app/domain data:

```bash
defaults delete io.github.sa1jer.rpgtodo desktopWindowPlacement.v1
```

## Manual Windows Smoke

1. Remove only `HKCU\Software\RPGToDo\WindowState`.
2. Launch and confirm maximized, non-fullscreen startup without a visible
   `1280 x 720` flash.
3. Restore, resize, move, close, and reopen; verify normal bounds.
4. Maximize, close, reopen, then unmaximize; verify both states.
5. Repeat on a secondary display and after disconnecting it.
6. Repeat at `100%`, `125%`, and `150%` scaling and with the taskbar on a
   non-default edge.

Native Windows runtime validation must be performed on Windows; a macOS build
cannot establish registry, monitor, or DPI behavior. A dedicated Windows-native
test target remains tracked in `TODO.md`; until it exists, the Windows branch is
covered by static review plus the manual smoke matrix above.
