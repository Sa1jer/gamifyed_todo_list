import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var lastNormalFrame = CGRect.zero
  private var closingWhileMaximized = false
  private var didPersistPlacement = false

  override func awakeFromNib() {
    let screens = NSScreen.screens
    let primaryFrame = screens.first?.visibleFrame ?? frame
    let startup = DesktopWindowPlacementPolicy.resolve(
      saved: DesktopWindowStateStore.shared.load(),
      visibleFrames: screens.map(\.visibleFrame),
      primaryFrame: primaryFrame
    )

    lastNormalFrame = startup.normalFrame
    setFrame(startup.normalFrame, display: false)
    animationBehavior = .none

    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    delegate = self

    if startup.shouldMaximize && !isZoomed {
      zoom(nil)
    }
  }

  func windowDidMove(_ notification: Notification) {
    captureNormalFrameIfNeeded()
  }

  func windowDidResize(_ notification: Notification) {
    captureNormalFrameIfNeeded()
  }

  func windowWillClose(_ notification: Notification) {
    closingWhileMaximized = isZoomed
    persistPlacement()
  }

  func persistPlacementForApplicationTermination() {
    closingWhileMaximized = isZoomed
    persistPlacement()
  }

  private func captureNormalFrameIfNeeded() {
    guard !isZoomed, !styleMask.contains(.fullScreen), !frame.isEmpty else {
      return
    }
    lastNormalFrame = frame
  }

  private func persistPlacement() {
    guard !didPersistPlacement, !lastNormalFrame.isEmpty else { return }
    DesktopWindowStateStore.shared.save(
      DesktopWindowSavedPlacement(
        normalFrame: lastNormalFrame,
        isMaximized: closingWhileMaximized || isZoomed
      )
    )
    didPersistPlacement = true
  }
}
