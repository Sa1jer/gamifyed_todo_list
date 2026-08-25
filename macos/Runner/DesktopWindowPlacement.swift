import Cocoa

struct DesktopWindowSavedPlacement: Equatable {
  let normalFrame: CGRect
  let isMaximized: Bool
}

struct DesktopWindowStartupPlacement: Equatable {
  let normalFrame: CGRect
  let shouldMaximize: Bool
}

enum DesktopWindowPlacementPolicy {
  static let minimumNormalSize = CGSize(width: 480, height: 360)
  static let minimumVisibleSize = CGSize(width: 120, height: 80)

  static func resolve(
    saved: DesktopWindowSavedPlacement?,
    visibleFrames: [CGRect],
    primaryFrame: CGRect
  ) -> DesktopWindowStartupPlacement {
    let usableFrames = visibleFrames.filter(isUsableScreenFrame)
    let fallbackScreen = isUsableScreenFrame(primaryFrame)
      ? primaryFrame
      : usableFrames.first ?? CGRect(x: 0, y: 0, width: 1280, height: 720)

    guard let saved, isValidNormalFrame(saved.normalFrame) else {
      return DesktopWindowStartupPlacement(
        normalFrame: centeredFallback(in: fallbackScreen),
        shouldMaximize: true
      )
    }

    let matchingScreen = usableFrames.max { lhs, rhs in
      intersectionArea(saved.normalFrame, lhs) < intersectionArea(saved.normalFrame, rhs)
    }
    let hasMeaningfulOverlap = matchingScreen.map {
      let intersection = saved.normalFrame.intersection($0)
      return !intersection.isNull
        && intersection.width >= minimumVisibleSize.width
        && intersection.height >= minimumVisibleSize.height
    } ?? false

    let normalFrame: CGRect
    if let matchingScreen, hasMeaningfulOverlap {
      normalFrame = clamp(saved.normalFrame, to: matchingScreen)
    } else {
      normalFrame = center(saved.normalFrame.size, in: fallbackScreen)
    }

    return DesktopWindowStartupPlacement(
      normalFrame: normalFrame,
      shouldMaximize: saved.isMaximized
    )
  }

  private static func isValidNormalFrame(_ frame: CGRect) -> Bool {
    frame.origin.x.isFinite
      && frame.origin.y.isFinite
      && frame.width.isFinite
      && frame.height.isFinite
      && frame.width >= minimumNormalSize.width
      && frame.height >= minimumNormalSize.height
  }

  private static func isUsableScreenFrame(_ frame: CGRect) -> Bool {
    frame.width >= minimumNormalSize.width && frame.height >= minimumNormalSize.height
  }

  private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
    let intersection = lhs.intersection(rhs)
    guard !intersection.isNull else { return 0 }
    return intersection.width * intersection.height
  }

  private static func centeredFallback(in screen: CGRect) -> CGRect {
    center(
      CGSize(
        width: min(1280, screen.width),
        height: min(800, screen.height)
      ),
      in: screen
    )
  }

  private static func center(_ requestedSize: CGSize, in screen: CGRect) -> CGRect {
    let width = min(max(requestedSize.width, minimumNormalSize.width), screen.width)
    let height = min(max(requestedSize.height, minimumNormalSize.height), screen.height)
    return CGRect(
      x: screen.minX + (screen.width - width) / 2,
      y: screen.minY + (screen.height - height) / 2,
      width: width,
      height: height
    )
  }

  private static func clamp(_ frame: CGRect, to screen: CGRect) -> CGRect {
    let width = min(frame.width, screen.width)
    let height = min(frame.height, screen.height)
    return CGRect(
      x: min(max(frame.minX, screen.minX), screen.maxX - width),
      y: min(max(frame.minY, screen.minY), screen.maxY - height),
      width: width,
      height: height
    )
  }
}

final class DesktopWindowStateStore {
  static let shared = DesktopWindowStateStore()

  private let defaults: UserDefaults
  private let key: String

  init(
    defaults: UserDefaults = .standard,
    key: String = "desktopWindowPlacement.v1"
  ) {
    self.defaults = defaults
    self.key = key
  }

  func load() -> DesktopWindowSavedPlacement? {
    guard
      let value = defaults.dictionary(forKey: key),
      number(value["version"])?.intValue == 1,
      let x = number(value["x"])?.doubleValue,
      let y = number(value["y"])?.doubleValue,
      let width = number(value["width"])?.doubleValue,
      let height = number(value["height"])?.doubleValue,
      let isMaximized = value["isMaximized"] as? Bool
    else {
      return nil
    }

    return DesktopWindowSavedPlacement(
      normalFrame: CGRect(x: x, y: y, width: width, height: height),
      isMaximized: isMaximized
    )
  }

  func save(_ placement: DesktopWindowSavedPlacement) {
    defaults.set(
      [
        "version": 1,
        "x": placement.normalFrame.origin.x,
        "y": placement.normalFrame.origin.y,
        "width": placement.normalFrame.width,
        "height": placement.normalFrame.height,
        "isMaximized": placement.isMaximized,
      ],
      forKey: key
    )
  }

  private func number(_ value: Any?) -> NSNumber? {
    value as? NSNumber
  }
}
