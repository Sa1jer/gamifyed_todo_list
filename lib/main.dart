// To-Do List RPG 1.0.6
// Entry point — kept minimal (~90 lines)

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'app_state.dart';
import 'theme/app_typography.dart';
import 'utils.dart';
import 'widgets/main_page.dart';
import 'widgets/persistence_recovery.dart';

final _storage = StorageService();
final _notifications = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _notifications.init();
  runApp(RPGApp(storage: _storage));
}

// ═══════════════════════════════════════════════════════════════════════════════
// CORNER-REVEAL THEME TRANSITION
// ═══════════════════════════════════════════════════════════════════════════════

class _RevealClipper extends CustomClipper<Path> {
  final double progress;
  final Offset corner;
  _RevealClipper({required this.progress, required this.corner});

  @override
  Path getClip(Size size) {
    final diag = Offset(size.width, size.height).distance;
    final radius = (diag * (1.0 - progress)).clamp(0.0, diag * 2);
    return Path()..addOval(Rect.fromCircle(center: corner, radius: radius));
  }

  @override
  bool shouldReclip(_RevealClipper o) =>
      o.progress != progress || o.corner != corner;
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════════════════════════

class RPGApp extends StatefulWidget {
  final StorageService storage;
  final Future<ui.Image?> Function()? captureFrameForTesting;

  const RPGApp({super.key, required this.storage, this.captureFrameForTesting});
  @override
  State<RPGApp> createState() => _RPGAppState();
}

class _RPGAppState extends State<RPGApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AppState _state;
  final _repaintKey = GlobalKey();

  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;
  ui.Image? _overlayImage;
  Offset _revealCorner = Offset.zero;
  bool _revealing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = AppState(storage: widget.storage, seedDefaults: false);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeInOutCubic,
    );
    unawaited(_initializeStorageAndLoad());
  }

  Future<void> _initializeStorageAndLoad() async {
    try {
      await widget.storage.init();
    } catch (error, stackTrace) {
      if (!mounted) return;
      _state.reportStartupStorageFailure(error, stackTrace);
      return;
    }
    if (!mounted) return;
    await _state.retryLoadSavedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayImage?.dispose();
    _overlayImage = null;
    _state.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _state.resumeBackgroundWork();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _state.pauseBackgroundWork();
        break;
    }
  }

  Future<void> _handleThemeToggle() async {
    if (_revealing) return;
    _revealing = true;
    ui.Image? capturedFrame;

    try {
      capturedFrame = await _captureCurrentFrame();
      if (!mounted) {
        capturedFrame?.dispose();
        capturedFrame = null;
        return;
      }

      _revealCorner = _resolveRevealCorner();
      _state.toggleTheme();
      setState(() {});
      final hasFrame = capturedFrame != null;
      _setOverlayImage(capturedFrame);
      capturedFrame = null; // Ownership transferred to _overlayImage.

      if (hasFrame) {
        _revealCtrl.value = 0;
        await _revealCtrl.forward();
      }
    } finally {
      capturedFrame?.dispose();
      if (mounted) _setOverlayImage(null);
      _revealing = false;
    }
  }

  static ThemeData _buildTheme(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: brightness,
    ).copyWith(surface: surface(dark));
    final textTheme = AppTypography.textTheme(colorScheme);
    return ThemeData(
      brightness: brightness,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0F0F13)
          : const Color(0xFFF0F2F8),
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [AppTextRoles.fromTheme(textTheme, brightness: brightness)],
      cardColor: surface(dark),
      dividerColor: borderColor(dark),
    );
  }

  Future<ui.Image?> _captureCurrentFrame() async {
    final captureForTesting = widget.captureFrameForTesting;
    if (captureForTesting != null) return captureForTesting();
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final pixelRatio = View.of(
        context,
      ).devicePixelRatio.clamp(1.0, 2.0).toDouble();
      return await boundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }

  Offset _resolveRevealCorner() {
    final size = MediaQuery.sizeOf(context);
    return _state.isDark ? Offset(size.width, 0) : Offset(0, size.height);
  }

  void _setOverlayImage(ui.Image? image) {
    if (!mounted) {
      image?.dispose();
      return;
    }
    final previous = _overlayImage;
    setState(() => _overlayImage = image);
    if (!identical(previous, image)) previous?.dispose();
  }

  Widget _buildRevealOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _revealAnim,
          builder: (_, child) => ClipPath(
            clipper: _RevealClipper(
              progress: _revealAnim.value,
              corner: _revealCorner,
            ),
            child: child,
          ),
          child: RawImage(
            image: _overlayImage,
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_state.isDark),
      home: AppStateProvider(
        state: _state,
        child: _AppContent(
          state: _state,
          onRetryLoad: _initializeStorageAndLoad,
          child: Stack(
            children: [
              RepaintBoundary(
                key: _repaintKey,
                child: MainPage(
                  state: _state,
                  onToggleTheme: _handleThemeToggle,
                ),
              ),
              if (_overlayImage != null) _buildRevealOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent({
    required this.state,
    required this.onRetryLoad,
    required this.child,
  });

  final AppState state;
  final Future<void> Function() onRetryLoad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppStateSelector(
      state: state,
      selector: (state) {
        final status = state.persistenceStatus;
        return (
          loaded: state.hasLoadedSavedData,
          tooltips: state.tooltipsEnabled,
          phase: status.phase,
          message: status.message,
          debugDetails: status.debugDetails,
          canRetry: status.canRetry,
          isDirty: status.isDirty,
          blocksSaving: status.blocksSaving,
        );
      },
      child: child,
      builder: (context, selection, child) => PersistenceGate(
        state: state,
        onRetryLoad: onRetryLoad,
        child: TooltipVisibility(visible: selection.tooltips, child: child!),
      ),
    );
  }
}
