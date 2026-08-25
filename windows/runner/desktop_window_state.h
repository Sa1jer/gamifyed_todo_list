#ifndef RUNNER_DESKTOP_WINDOW_STATE_H_
#define RUNNER_DESKTOP_WINDOW_STATE_H_

#include <windows.h>

struct DesktopWindowStartupPlacement {
  RECT normal_bounds;
  bool should_maximize;
};

// Stores native window geometry independently from Flutter domain persistence.
class DesktopWindowStateStore {
 public:
  // Resolves a visible normal frame before the first Flutter surface is shown.
  static DesktopWindowStartupPlacement ResolveStartupPlacement(HWND window);

  // Persists the last normal frame separately from the maximized flag.
  static void Save(const RECT& normal_bounds,
                   bool is_maximized,
                   UINT dpi);
};

#endif  // RUNNER_DESKTOP_WINDOW_STATE_H_
