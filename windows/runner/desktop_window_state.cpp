#include "desktop_window_state.h"

#include <flutter_windows.h>

#include <algorithm>
#include <cstdint>
#include <optional>
#include <vector>

namespace {

constexpr wchar_t kRegistryPath[] = L"Software\\RPGToDo\\WindowState";
constexpr DWORD kStorageVersion = 1;
constexpr LONG kMinimumWidth = 480;
constexpr LONG kMinimumHeight = 360;
constexpr LONG kMinimumVisibleWidth = 120;
constexpr LONG kMinimumVisibleHeight = 80;

struct SavedPlacement {
  RECT normal_bounds;
  bool is_maximized;
  UINT dpi;
};

struct MonitorWorkArea {
  HMONITOR monitor;
  RECT work_area;
};

std::optional<DWORD> ReadDword(HKEY key, const wchar_t* name) {
  DWORD value = 0;
  DWORD size = sizeof(value);
  const LSTATUS result = RegGetValueW(key, nullptr, name, RRF_RT_REG_DWORD,
                                      nullptr, &value, &size);
  if (result != ERROR_SUCCESS) {
    return std::nullopt;
  }
  return value;
}

void WriteDword(HKEY key, const wchar_t* name, DWORD value) {
  RegSetValueExW(key, name, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&value), sizeof(value));
}

LONG DecodeSigned(DWORD value) {
  return static_cast<LONG>(static_cast<std::int32_t>(value));
}

std::optional<SavedPlacement> LoadSavedPlacement() {
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &key) !=
      ERROR_SUCCESS) {
    return std::nullopt;
  }

  const auto version = ReadDword(key, L"Version");
  const auto left = ReadDword(key, L"Left");
  const auto top = ReadDword(key, L"Top");
  const auto right = ReadDword(key, L"Right");
  const auto bottom = ReadDword(key, L"Bottom");
  const auto maximized = ReadDword(key, L"Maximized");
  const auto dpi = ReadDword(key, L"Dpi");
  RegCloseKey(key);

  if (!version || *version != kStorageVersion || !left || !top || !right ||
      !bottom || !maximized || !dpi || *dpi == 0) {
    return std::nullopt;
  }

  return SavedPlacement{
      RECT{DecodeSigned(*left), DecodeSigned(*top), DecodeSigned(*right),
           DecodeSigned(*bottom)},
      *maximized != 0,
      *dpi,
  };
}

BOOL CALLBACK CollectMonitor(HMONITOR monitor,
                             HDC,
                             LPRECT,
                             LPARAM data) {
  auto* areas = reinterpret_cast<std::vector<MonitorWorkArea>*>(data);
  MONITORINFO info{sizeof(info)};
  if (GetMonitorInfoW(monitor, &info)) {
    areas->push_back(MonitorWorkArea{monitor, info.rcWork});
  }
  return TRUE;
}

std::vector<MonitorWorkArea> MonitorWorkAreas() {
  std::vector<MonitorWorkArea> areas;
  EnumDisplayMonitors(nullptr, nullptr, CollectMonitor,
                      reinterpret_cast<LPARAM>(&areas));
  return areas;
}

MonitorWorkArea PrimaryWorkArea(HWND window,
                                const std::vector<MonitorWorkArea>& areas) {
  const POINT primary_point{0, 0};
  HMONITOR primary = MonitorFromPoint(primary_point, MONITOR_DEFAULTTOPRIMARY);
  for (const auto& area : areas) {
    if (area.monitor == primary) {
      return area;
    }
  }

  if (!areas.empty()) {
    return areas.front();
  }

  RECT fallback{0, 0, 1280, 720};
  SystemParametersInfoW(SPI_GETWORKAREA, 0, &fallback, 0);
  return MonitorWorkArea{MonitorFromWindow(window, MONITOR_DEFAULTTOPRIMARY),
                         fallback};
}

LONG Width(const RECT& rect) {
  return rect.right - rect.left;
}

LONG Height(const RECT& rect) {
  return rect.bottom - rect.top;
}

LONG ScaleForDpi(LONG value, UINT source_dpi, UINT target_dpi) {
  return MulDiv(value, target_dpi, source_dpi == 0 ? 96 : source_dpi);
}

LONG MinimumWidthForDpi(UINT dpi) {
  return ScaleForDpi(kMinimumWidth, 96, dpi == 0 ? 96 : dpi);
}

LONG MinimumHeightForDpi(UINT dpi) {
  return ScaleForDpi(kMinimumHeight, 96, dpi == 0 ? 96 : dpi);
}

bool IsValid(const RECT& rect, UINT dpi) {
  return Width(rect) >= MinimumWidthForDpi(dpi) &&
         Height(rect) >= MinimumHeightForDpi(dpi);
}

long long IntersectionArea(const RECT& lhs, const RECT& rhs) {
  const LONG width =
      std::max<LONG>(0, std::min(lhs.right, rhs.right) -
                            std::max(lhs.left, rhs.left));
  const LONG height =
      std::max<LONG>(0, std::min(lhs.bottom, rhs.bottom) -
                            std::max(lhs.top, rhs.top));
  return static_cast<long long>(width) * height;
}

bool HasMeaningfulOverlap(const RECT& frame, const RECT& work_area) {
  const LONG width =
      std::max<LONG>(0, std::min(frame.right, work_area.right) -
                            std::max(frame.left, work_area.left));
  const LONG height =
      std::max<LONG>(0, std::min(frame.bottom, work_area.bottom) -
                            std::max(frame.top, work_area.top));
  return width >= kMinimumVisibleWidth && height >= kMinimumVisibleHeight;
}

RECT CenteredRect(LONG width, LONG height, const RECT& work_area) {
  width = std::min(width, Width(work_area));
  height = std::min(height, Height(work_area));
  const LONG left = work_area.left + (Width(work_area) - width) / 2;
  const LONG top = work_area.top + (Height(work_area) - height) / 2;
  return RECT{left, top, left + width, top + height};
}

RECT ClampRect(const RECT& frame, const RECT& work_area) {
  const LONG width = std::min(Width(frame), Width(work_area));
  const LONG height = std::min(Height(frame), Height(work_area));
  const LONG left = std::min(
      std::max(frame.left, work_area.left), work_area.right - width);
  const LONG top = std::min(
      std::max(frame.top, work_area.top), work_area.bottom - height);
  return RECT{left, top, left + width, top + height};
}

}  // namespace

DesktopWindowStartupPlacement
DesktopWindowStateStore::ResolveStartupPlacement(HWND window) {
  const auto areas = MonitorWorkAreas();
  const auto primary = PrimaryWorkArea(window, areas);
  const auto saved = LoadSavedPlacement();

  if (!saved || !IsValid(saved->normal_bounds, saved->dpi)) {
    const UINT dpi = FlutterDesktopGetDpiForMonitor(primary.monitor);
    const LONG width = ScaleForDpi(1280, 96, dpi);
    const LONG height = ScaleForDpi(800, 96, dpi);
    return DesktopWindowStartupPlacement{
        CenteredRect(width, height, primary.work_area), true};
  }

  const MonitorWorkArea* target = nullptr;
  long long largest_overlap = 0;
  for (const auto& area : areas) {
    const long long overlap =
        IntersectionArea(saved->normal_bounds, area.work_area);
    if (overlap > largest_overlap) {
      largest_overlap = overlap;
      target = &area;
    }
  }

  if (target && HasMeaningfulOverlap(saved->normal_bounds, target->work_area)) {
    const UINT target_dpi = FlutterDesktopGetDpiForMonitor(target->monitor);
    const LONG scaled_width = std::max(
        ScaleForDpi(Width(saved->normal_bounds), saved->dpi, target_dpi),
        MinimumWidthForDpi(target_dpi));
    const LONG scaled_height = std::max(
        ScaleForDpi(Height(saved->normal_bounds), saved->dpi, target_dpi),
        MinimumHeightForDpi(target_dpi));
    RECT scaled = saved->normal_bounds;
    scaled.right = scaled.left + scaled_width;
    scaled.bottom = scaled.top + scaled_height;
    return DesktopWindowStartupPlacement{
        ClampRect(scaled, target->work_area), saved->is_maximized};
  }

  const UINT primary_dpi = FlutterDesktopGetDpiForMonitor(primary.monitor);
  const LONG width = std::max(
      ScaleForDpi(Width(saved->normal_bounds), saved->dpi, primary_dpi),
      MinimumWidthForDpi(primary_dpi));
  const LONG height = std::max(
      ScaleForDpi(Height(saved->normal_bounds), saved->dpi, primary_dpi),
      MinimumHeightForDpi(primary_dpi));
  return DesktopWindowStartupPlacement{
      CenteredRect(width, height, primary.work_area), saved->is_maximized};
}

void DesktopWindowStateStore::Save(const RECT& normal_bounds,
                                   bool is_maximized,
                                   UINT dpi) {
  if (!IsValid(normal_bounds, dpi)) {
    return;
  }

  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr, 0,
                      KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }

  WriteDword(key, L"Version", kStorageVersion);
  WriteDword(key, L"Left", static_cast<DWORD>(normal_bounds.left));
  WriteDword(key, L"Top", static_cast<DWORD>(normal_bounds.top));
  WriteDword(key, L"Right", static_cast<DWORD>(normal_bounds.right));
  WriteDword(key, L"Bottom", static_cast<DWORD>(normal_bounds.bottom));
  WriteDword(key, L"Maximized", is_maximized ? 1 : 0);
  WriteDword(key, L"Dpi", dpi == 0 ? 96 : dpi);
  RegCloseKey(key);
}
