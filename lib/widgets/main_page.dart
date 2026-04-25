import 'package:flutter/material.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';
import 'skills_panel.dart';
import 'tasks_panel.dart';
import 'profile_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppState state;
  const TopBar({super.key, required this.isDark, required this.onToggle, required this.state});

  @override
  Widget build(BuildContext context) {
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      color: sfc,
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 12),
      child: Row(children: [
        const Icon(Icons.security, color: Color(0xFF4A9EFF), size: 20),
        const SizedBox(width: 8),
        Text('RPG To-Do List',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: txt)),
        const Spacer(),
        HoverIconBtn(
          icon: Icons.emoji_events,
          color: sub,
          onTap: () => showDialog(
            context: context,
            builder: (_) => AchievementsDialog(achievements: state.achievements, isDark: isDark),
          ),
        ),
        const SizedBox(width: 4),
        HoverIconBtn(
          icon: Icons.history, color: sub,
          onTap: () => showDialog(
            context: context,
            builder: (_) => HistoryDialog(history: state.history, isDark: isDark),
          ),
        ),
        const SizedBox(width: 4),
        HoverIconBtn(
          icon: Icons.bar_chart,
          color: sub,
          onTap: () => showDialog(
            context: context,
            builder: (_) => StatsDialog(state: state),
          ),
        ),
        const SizedBox(width: 4),
        HoverIconBtn(
          icon: Icons.shield,
          color: sub,
          onTap: () => showDialog(
            context: context,
            builder: (_) => BossesDialog(state: state),
          ),
        ),
        const SizedBox(width: 4),
        HoverIconBtn(
          icon: Icons.calendar_month,
          color: sub,
          onTap: () => showDialog(
            context: context,
            builder: (_) => CalendarDialog(state: state),
          ),
        ),
        const SizedBox(width: 4),
        HoverIconBtn(
          icon: isDark ? Icons.light_mode : Icons.dark_mode,
          color: sub, onTap: onToggle,
        ),
        const SizedBox(width: 4),
        HoverIconBtn(icon: Icons.settings, color: sub, onTap: () {}),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE BAR
// Direct AppStateProvider consumer for immediate XP bar updates.
// Avatar, name, and level badge all open the Profile dialog on tap.
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileBar extends StatelessWidget {
  final bool isDark;
  const ProfileBar({super.key, required this.isDark});

  void _openProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppStateProvider(
        state: AppStateProvider.of(context),
        child: const ProfileDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppStateProvider.of(context).profile;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      color: sfc,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Row(children: [
        // Avatar — clickable → profile
        HoverScale(
          child: GestureDetector(
            onTap: () => _openProfile(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: profile.avatarBytes == null
                    ? const LinearGradient(
                        colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                image: profile.avatarBytes != null
                    ? DecorationImage(
                        image: MemoryImage(profile.avatarBytes!), fit: BoxFit.cover)
                    : null,
                shape: BoxShape.circle,
              ),
              child: profile.avatarBytes == null
                  ? Center(child: Text(profile.initial,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Name — clickable → profile
            GestureDetector(
              onTap: () => _openProfile(context),
              child: Text(profile.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: txt)),
            ),
            const SizedBox(width: 8),
            // Level badge — clickable → profile
            GestureDetector(
              onTap: () => _openProfile(context),
              child: LvlBadge(level: profile.level, color: const Color(0xFF4A9EFF)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: XPBar(
                progress: profile.progress, color: const Color(0xFF4A9EFF), height: 8)),
            const SizedBox(width: 10),
            Text('${profile.xp} / ${profile.xpNeeded} XP',
                style: TextStyle(color: sub, fontSize: 11)),
          ]),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainPage({super.key, required this.onToggleTheme});
  @override State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<XPBubble> _bubbles = [];

  void _onComplete(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeTask(taskId);
    if (msg == null) return;
    setState(() {
      _bubbles.add(XPBubble(
        key: UniqueKey(), message: msg, position: pos,
        onDone: (k) => setState(() => _bubbles.removeWhere((b) => b.key == k)),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s      = AppStateProvider.of(context);
    final isDark = s.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF0F2F8),
      body: Stack(children: [
        Column(children: [
          TopBar(isDark: isDark, onToggle: widget.onToggleTheme, state: s),
          ProfileBar(isDark: isDark),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(width: 380, child: SkillsPanel()),
                const SizedBox(width: 12),
                Expanded(child: TasksPanel(onComplete: _onComplete)),
              ]),
            ),
          ),
        ]),
        ..._bubbles,
      ]),
    );
  }
}
