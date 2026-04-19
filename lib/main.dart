// To-Do List RPG 1.0.5
// Entry point — kept minimal (~90 lines)

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app_state.dart';
import 'utils.dart';
import 'widgets/main_page.dart';

void main() => runApp(const RPGApp());

// ═══════════════════════════════════════════════════════════════════════════════
// CORNER-REVEAL THEME TRANSITION
// ═══════════════════════════════════════════════════════════════════════════════

class _RevealClipper extends CustomClipper<Path> {
  final double progress;
  final Offset corner;
  _RevealClipper({required this.progress, required this.corner});

  @override
  Path getClip(Size size) {
    final diag   = Offset(size.width, size.height).distance;
    final radius = (diag * (1.0 - progress)).clamp(0.0, diag * 2);
    return Path()..addOval(Rect.fromCircle(center: corner, radius: radius));
  }

  @override
  bool shouldReclip(_RevealClipper o) => o.progress != progress || o.corner != corner;
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════════════════════════

class RPGApp extends StatefulWidget {
  const RPGApp({super.key});
  @override State<RPGApp> createState() => _RPGAppState();
}

class _RPGAppState extends State<RPGApp> with SingleTickerProviderStateMixin {
  final AppState _state    = AppState();
  final _repaintKey        = GlobalKey();

  late AnimationController _revealCtrl;
  late Animation<double>   _revealAnim;
  ui.Image? _overlayImage;
  Offset    _revealCorner = Offset.zero;
  bool      _revealing    = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeInOutCubic);
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    _state.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleThemeToggle() async {
    if (_revealing) return;
    _revealing = true;

    ui.Image? frame;
    try {
      final b = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b != null) frame = await b.toImage(pixelRatio: View.of(context).devicePixelRatio);
    } catch (_) {}

    if (!mounted) { _revealing = false; return; }

    final size    = MediaQuery.of(context).size;
    _revealCorner = _state.isDark ? Offset(size.width, 0) : Offset(0, size.height);
    _state.isDark = !_state.isDark;
    setState(() { _overlayImage = frame; });

    if (frame != null) { _revealCtrl.value = 0; await _revealCtrl.forward(); }
    setState(() { _overlayImage = null; });
    _revealing = false;
  }

  static ThemeData _buildTheme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F0F13) : const Color(0xFFF0F2F8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(surface: surface(dark)),
    cardColor:    surface(dark),
    dividerColor: borderColor(dark),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_state.isDark),
      home: AppStateProvider(
        state: _state,
        child: Stack(children: [
          RepaintBoundary(
            key: _repaintKey,
            child: MainPage(onToggleTheme: _handleThemeToggle),
          ),
          if (_overlayImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _revealAnim,
                  builder: (_, _x) => ClipPath(
                    clipper: _RevealClipper(progress: _revealAnim.value, corner: _revealCorner),
                    child: RawImage(
                      image: _overlayImage, fit: BoxFit.fill,
                      width: double.infinity, height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
