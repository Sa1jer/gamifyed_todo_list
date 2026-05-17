// To-Do List RPG 1.0.6
// Entry point — kept minimal (~90 lines)

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'app_state.dart';
import 'utils.dart';
import 'widgets/main_page.dart';

final _storage = StorageService();
final _notifications = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _storage.init();
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
  const RPGApp({super.key, required this.storage});
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
    _state.addListener(_onStateChange);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeInOutCubic,
    );
    _state.loadSavedData();
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_onStateChange);
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

    try {
      final frame = await _captureCurrentFrame();
      if (!mounted) return;

      _revealCorner = _resolveRevealCorner();
      _state.toggleTheme();
      _setOverlayImage(frame);

      if (frame != null) {
        _revealCtrl.value = 0;
        await _revealCtrl.forward();
      }

      _setOverlayImage(null);
    } finally {
      _revealing = false;
    }
  }

  static ThemeData _buildTheme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF0F2F8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(surface: surface(dark)),
    cardColor: surface(dark),
    dividerColor: borderColor(dark),
  );

  Future<ui.Image?> _captureCurrentFrame() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );
    } catch (_) {
      return null;
    }
  }

  Offset _resolveRevealCorner() {
    final size = MediaQuery.sizeOf(context);
    return _state.isDark ? Offset(size.width, 0) : Offset(0, size.height);
  }

  void _setOverlayImage(ui.Image? image) {
    if (!mounted) return;
    setState(() => _overlayImage = image);
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
        child: Stack(
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: MainPage(onToggleTheme: _handleThemeToggle),
            ),
            if (_overlayImage != null) _buildRevealOverlay(),
          ],
        ),
      ),
    );
  }
}
