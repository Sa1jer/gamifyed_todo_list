import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../utils.dart';
import '../widgets/shared.dart';

Future<void> showDebugAdminPanel(
  BuildContext context, {
  required AppState state,
}) {
  assert(kDebugMode, 'Debug Admin must not be used outside debug mode');
  return showDialog<void>(
    context: context,
    builder: (_) => _DebugAdminPanel(state: state),
  );
}

class _DebugAdminPanel extends StatelessWidget {
  final AppState state;

  const _DebugAdminPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final border = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withAlpha(22),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withAlpha(62),
                      ),
                    ),
                    child: const Icon(
                      Icons.bug_report_outlined,
                      color: Color(0xFFFF9500),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBUG ADMIN',
                          style: TextStyle(
                            color: txt,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'State Simulator shell',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PressFeedback(
                    scale: 0.92,
                    tooltip: 'Закрыть Debug Admin',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withAlpha(13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9500).withAlpha(45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF9500),
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Debug only. Инструменты симуляции состояния появятся в следующих фазах.',
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.2,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    _DebugAdminSection(
                      icon: Icons.auto_fix_high_outlined,
                      title: 'Сценарии',
                      description:
                          'Fresh user, streak, trophies and load states.',
                    ),
                    _DebugAdminSection(
                      icon: Icons.emoji_events_outlined,
                      title: 'Достижения',
                      description:
                          'Unlock, lock and inspect achievement state.',
                    ),
                    _DebugAdminSection(
                      icon: Icons.person_outline,
                      title: 'Профиль',
                      description: 'Level, XP and profile test values.',
                    ),
                    _DebugAdminSection(
                      icon: Icons.inventory_2_outlined,
                      title: 'Сундуки и эффекты',
                      description: 'Pending chests and active passive effects.',
                    ),
                    _DebugAdminSection(
                      icon: Icons.shield_outlined,
                      title: 'Сопротивление',
                      description:
                          'Sample resistance events and defeated states.',
                    ),
                    _DebugAdminSection(
                      icon: Icons.delete_outline,
                      title: 'Reset tools',
                      description:
                          'Dangerous reset actions will require confirmation.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: border),
              const SizedBox(height: 10),
              Text(
                'Read-only shell in 1.3.40 · no AppState mutations',
                style: TextStyle(
                  color: sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugAdminSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DebugAdminSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context).brightness == Brightness.dark;
    final txt = textColor(inherited);
    final sub = subtext(inherited);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inherited ? const Color(0xFF15151D) : const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor(inherited)),
      ),
      child: Row(
        children: [
          Icon(icon, color: sub, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.2,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'скоро',
            style: TextStyle(
              color: sub,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
