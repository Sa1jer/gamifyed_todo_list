import 'package:flutter/material.dart';
import '../utils.dart';

const _kPanelRadius = 14.0;

class AppPanel extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AppPanel({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: child,
    );
  }
}

class PanelDivider extends StatelessWidget {
  final bool isDark;

  const PanelDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: borderColor(isDark));
  }
}

class EmptyStateMessage extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateMessage({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sub, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: sub,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: sub.withAlpha(160), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRESS FEEDBACK WRAPPER
// ═══════════════════════════════════════════════════════════════════════════════

class PressFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const PressFeedback({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.93,
  });
  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) {
      setState(() => _p = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? widget.scale : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _p ? 0.82 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    ),
  );
}

class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Alignment alignment;
  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.068,
    this.duration = const Duration(milliseconds: 160),
    this.alignment = Alignment.center,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: AnimatedScale(
      scale: _h ? widget.scale : 1.0,
      alignment: widget.alignment,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL BUTTON  (solid color, press = scale + darken)
// ═══════════════════════════════════════════════════════════════════════════════

class SmallBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const SmallBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<SmallBtn> createState() => _SmallBtnState();
}

class _SmallBtnState extends State<SmallBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) {
      setState(() => _p = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _p ? darken(widget.color) : widget.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MINI ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class MiniBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const MiniBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<MiniBtn> createState() => _MiniBtnState();
}

class _MiniBtnState extends State<MiniBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) {
      setState(() => _p = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.78 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: _p ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(widget.icon, size: 17, color: widget.color),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOVER ICON BUTTON (TopBar)
// ═══════════════════════════════════════════════════════════════════════════════

class HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const HoverIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<HoverIconBtn> {
  bool _h = false, _p = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() {
      _h = false;
      _p = false;
    }),
    child: GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _h || _p ? widget.color.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED XP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class XPBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  const XPBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });
  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _a = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_c);
    _prev = widget.progress;
    _c.forward();
  }

  @override
  void didUpdateWidget(XPBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _a = Tween<double>(
        begin: _prev,
        end: widget.progress,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_c);
      _prev = widget.progress;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, child) => ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: LinearProgressIndicator(
        value: _a.value.clamp(0.0, 1.0),
        minHeight: widget.height,
        backgroundColor: widget.color.withAlpha(35),
        valueColor: AlwaysStoppedAnimation(widget.color),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEVEL BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class LvlBadge extends StatelessWidget {
  final int level;
  final Color color;
  const LvlBadge({super.key, required this.level, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(
      'Lvl $level',
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// BADGE (small colored label)
// ═══════════════════════════════════════════════════════════════════════════════

class TaskBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const TaskBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING XP BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

class XPBubble extends StatefulWidget {
  final String message;
  final Offset position;
  final Function(Key?) onDone;
  const XPBubble({
    super.key,
    required this.message,
    required this.position,
    required this.onDone,
  });
  @override
  State<XPBubble> createState() => _XPBubbleState();
}

class _XPBubbleState extends State<XPBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _y, _o;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _y = Tween<double>(
      begin: 0,
      end: -90,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _o = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 12),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 53),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 35),
    ]).animate(_c);
    _c.forward().then((_) => widget.onDone(widget.key));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy + _y.value,
      child: Opacity(opacity: _o.value, child: child),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9EFF).withAlpha(100),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        widget.message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIALOG SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class DlgHeader extends StatelessWidget {
  final String title;
  final Color txtColor;
  const DlgHeader({super.key, required this.title, required this.txtColor});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: txtColor,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      PressFeedback(
        scale: 0.82,
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Color(0xFF8E8E93), size: 22),
      ),
    ],
  );
}

class DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color fBg, txt, sub, bdr;
  final int min;
  const DlgField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.fBg,
    required this.txt,
    required this.sub,
    required this.bdr,
    this.min = 1,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SubLbl(label, sub),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: fBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bdr),
        ),
        child: TextField(
          controller: ctrl,
          style: TextStyle(color: txt, fontSize: 14),
          minLines: min,
          maxLines: min == 1 ? 1 : 4,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ],
  );
}

class DlgActions extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  const DlgActions({super.key, required this.onCancel, required this.onSave});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      PressFeedback(
        onTap: onCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      PressFeedback(
        onTap: onSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Сохранить',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ],
  );
}

class SubLbl extends StatelessWidget {
  final String text;
  final Color color;
  const SubLbl(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}
