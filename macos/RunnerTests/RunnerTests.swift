import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {
  private let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)

  func testMissingStateUsesCenteredNormalFrameAndMaximizes() {
    let result = DesktopWindowPlacementPolicy.resolve(
      saved: nil,
      visibleFrames: [primary],
      primaryFrame: primary
    )

    XCTAssertTrue(result.shouldMaximize)
    XCTAssertEqual(result.normalFrame.size, CGSize(width: 1280, height: 800))
    XCTAssertEqual(result.normalFrame.midX, primary.midX)
    XCTAssertEqual(result.normalFrame.midY, primary.midY)
  }

  func testNormalStateRestoresWithoutMaximizing() {
    let frame = CGRect(x: 120, y: 100, width: 1000, height: 700)
    let result = DesktopWindowPlacementPolicy.resolve(
      saved: DesktopWindowSavedPlacement(normalFrame: frame, isMaximized: false),
      visibleFrames: [primary],
      primaryFrame: primary
    )

    XCTAssertFalse(result.shouldMaximize)
    XCTAssertEqual(result.normalFrame, frame)
  }

  func testMaximizedStateKeepsLastNormalFrame() {
    let frame = CGRect(x: 160, y: 120, width: 960, height: 640)
    let result = DesktopWindowPlacementPolicy.resolve(
      saved: DesktopWindowSavedPlacement(normalFrame: frame, isMaximized: true),
      visibleFrames: [primary],
      primaryFrame: primary
    )

    XCTAssertTrue(result.shouldMaximize)
    XCTAssertEqual(result.normalFrame, frame)
  }

  func testPartiallyOffscreenFrameIsClampedToVisibleWorkArea() {
    let result = DesktopWindowPlacementPolicy.resolve(
      saved: DesktopWindowSavedPlacement(
        normalFrame: CGRect(x: 1320, y: 100, width: 900, height: 650),
        isMaximized: false
      ),
      visibleFrames: [primary],
      primaryFrame: primary
    )

    XCTAssertEqual(result.normalFrame.maxX, primary.maxX)
    XCTAssertEqual(result.normalFrame.minY, 100)
  }

  func testDisconnectedMonitorCentersFrameOnPrimary() {
    let result = DesktopWindowPlacementPolicy.resolve(
      saved: DesktopWindowSavedPlacement(
        normalFrame: CGRect(x: 2400, y: 200, width: 900, height: 600),
        isMaximized: false
      ),
      visibleFrames: [primary],
      primaryFrame: primary
    )

    XCTAssertEqual(result.normalFrame.midX, primary.midX)
    XCTAssertEqual(result.normalFrame.midY, primary.midY)
    XCTAssertEqual(result.normalFrame.size, CGSize(width: 900, height: 600))
  }

  func testMalformedSavedValueFallsBackSafely() {
    let suite = "RunnerTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(["version": 1, "x": "invalid"], forKey: "window")

    let store = DesktopWindowStateStore(defaults: defaults, key: "window")

    XCTAssertNil(store.load())
  }

  func testStoreRoundTripsNormalFrameAndMaximizedFlag() {
    let suite = "RunnerTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let expected = DesktopWindowSavedPlacement(
      normalFrame: CGRect(x: -820, y: 60, width: 800, height: 600),
      isMaximized: true
    )
    let store = DesktopWindowStateStore(defaults: defaults, key: "window")

    store.save(expected)

    XCTAssertEqual(store.load(), expected)
  }
}
