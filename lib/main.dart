import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const RPGApp());

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

int _nextId = 0;
String uid() => '${++_nextId}';

/// Универсальный рендер иконок и эмодзи
Widget _buildIcon(dynamic iconData, Color color, double size) {
  if (iconData is IconData) {
    return Icon(iconData, color: color, size: size);
  } else if (iconData is String) {
    return Text(iconData, style: TextStyle(fontSize: size * 0.85, height: 1.0));
  }
  return Icon(Icons.star, color: color, size: size);
}

/// Линейно-ступенчатая прогрессия
int xpForLevel(int level) {
  if (level <= 3) {
    return 1000;
  }
  if (level <= 7) {
    return 2000;
  }
  if (level <= 10) {
    return 3000;
  }
  return 4000;
}

enum TaskType { repeating, shortTerm, midTerm, longTerm }

const _typeLabel = {
  TaskType.repeating: 'Повторяющаяся',
  TaskType.shortTerm: 'Краткосрочная',
  TaskType.midTerm: 'Среднесрочная',
  TaskType.longTerm: 'Долгосрочная',
};
const _typeColor = {
  TaskType.repeating: Color(0xFF4A9EFF),
  TaskType.shortTerm: Color(0xFF34C759),
  TaskType.midTerm: Color(0xFFFF9500),
  TaskType.longTerm: Color(0xFFFF3B30),
};
const _typeSoftCap = {
  TaskType.repeating: 100,
  TaskType.shortTerm: 200,
  TaskType.midTerm: 500,
  TaskType.longTerm: 1000,
};

enum RepeatFrequency { daily, every3Days, weekly, biweekly, monthly, custom }

const _freqLabel = {
  RepeatFrequency.daily: '1 раз за 1 день',
  RepeatFrequency.every3Days: 'раз в 3 дня',
  RepeatFrequency.weekly: 'раз в неделю',
  RepeatFrequency.biweekly: 'раз в 2 недели',
  RepeatFrequency.monthly: 'раз в месяц',
  RepeatFrequency.custom: 'персональная',
};

int _freqDays(RepeatFrequency f, int custom) => switch (f) {
  RepeatFrequency.daily => 1,
  RepeatFrequency.every3Days => 3,
  RepeatFrequency.weekly => 7,
  RepeatFrequency.biweekly => 14,
  RepeatFrequency.monthly => 30,
  RepeatFrequency.custom => custom,
};

/// 3:00 AM через N дней от сейчас
DateTime _nextReset(RepeatFrequency freq, int customDays) {
  final d = DateTime.now().add(Duration(days: _freqDays(freq, customDays)));
  return DateTime(d.year, d.month, d.day, 3, 0, 0);
}

// Theme helpers
Color _surface(bool d) => d ? const Color(0xFF1A1A24) : Colors.white;
Color _text(bool d) => d ? const Color(0xFFEEEEF4) : const Color(0xFF0D0D14);
Color _subtext(bool d) => d ? const Color(0xFF8E8E93) : const Color(0xFF555560);
Color _border(bool d) => d ? const Color(0xFF2A2A35) : const Color(0xFFD8D8E4);

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

mixin XPOwner {
  int get level;
  set level(int v);
  int get xp;
  set xp(int v);

  int get xpNeeded => xpForLevel(level);
  double get progress => (xp / xpNeeded).clamp(0.0, 1.0);

  int addXP(int amount) {
    xp += amount;
    int gained = 0;
    while (xp >= xpNeeded) {
      xp -= xpForLevel(level);
      level++;
      gained++;
    }
    return gained;
  }

  void removeXP(int amount) {
    xp = (xp - amount).clamp(0, 999999);
  }
}

class Skill with XPOwner {
  final String id;
  String name, goal;
  List<String> checklist;
  Color color;
  dynamic icon; // Позволяет хранить как IconData, так и Emoji
  @override
  int level, xp;

  Skill({
    required this.id,
    required this.name,
    required this.goal,
    required this.color,
    required this.icon,
    List<String>? checklist,
    this.level = 1,
    this.xp = 0,
  }) : checklist = checklist ?? [];

  String get initial => name.isNotEmpty ? name[0] : '?';
}

class Task {
  final String id;
  String title;
  String skillId;
  int xpReward;
  TaskType type;
  bool isDone;
  int streak, streakMultiplier, earnedXP;
  RepeatFrequency repeatFrequency;
  int repeatCustomDays;
  DateTime? nextResetAt;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.xpReward,
    required this.type,
    this.isDone = false,
    this.streak = 0,
    this.streakMultiplier = 1,
    this.earnedXP = 0,
    this.repeatFrequency = RepeatFrequency.daily,
    this.repeatCustomDays = 1,
    this.nextResetAt,
  });
}

class UserProfile with XPOwner {
  String name;
  @override
  int level, xp;
  UserProfile({required this.name, this.level = 1, this.xp = 0});
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class HistoryEntry {
  final String id;
  final String taskTitle;
  final String skillId;
  final String skillName;
  final Color skillColor;
  final dynamic skillIcon; // Позволяет хранить как IconData, так и Emoji
  final int xp;
  final bool isCompletion;
  final DateTime at;

  HistoryEntry({
    required this.id,
    required this.taskTitle,
    required this.skillId,
    required this.skillName,
    required this.skillColor,
    required this.skillIcon,
    required this.xp,
    required this.isCompletion,
    required this.at,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP STATE
// ═══════════════════════════════════════════════════════════════════════════════

class AppState extends ChangeNotifier {
  bool isDark = true;
  String? selectedSkillId;

  final UserProfile profile = UserProfile(name: 'Saijer');
  final List<HistoryEntry> history = [];

  final List<Skill> skills = [
    Skill(
      id: 's1',
      name: 'Подтягивания',
      goal: 'Подтягиваться 20 раз',
      color: const Color(0xFFFF9500),
      icon: Icons.fitness_center,
      xp: 60,
    ),
    Skill(
      id: 's2',
      name: 'Python',
      goal: 'Освоить backend на FastAPI',
      color: const Color(0xFF5856D6),
      icon: Icons.code,
      xp: 30,
      level: 2,
    ),
    Skill(
      id: 's3',
      name: 'Геймификация жизни',
      goal: 'Запустить RPGreal.org',
      color: const Color(0xFF34C759),
      icon: Icons.sports_esports,
      xp: 80,
    ),
  ];

  final List<Task> tasks = [
    Task(
      id: 't1',
      title: 'Сделать 3 подхода подтягиваний',
      skillId: 's1',
      xpReward: 25,
      type: TaskType.repeating,
      streak: 3,
      streakMultiplier: 2,
      repeatFrequency: RepeatFrequency.daily,
    ),
    Task(
      id: 't2',
      title: 'Выйти на 15 подтягиваний за сет',
      skillId: 's1',
      xpReward: 100,
      type: TaskType.longTerm,
    ),
    Task(
      id: 't3',
      title: 'Пройти урок: функции и замыкания',
      skillId: 's2',
      xpReward: 20,
      type: TaskType.shortTerm,
    ),
    Task(
      id: 't4',
      title: 'Написать REST API на FastAPI',
      skillId: 's2',
      xpReward: 60,
      type: TaskType.midTerm,
    ),
    Task(
      id: 't5',
      title: 'Написать концепцию монетизации',
      skillId: 's3',
      xpReward: 50,
      type: TaskType.midTerm,
      streak: 2,
      streakMultiplier: 2,
    ),
  ];

  AppState() {
    _checkResets();
  }

  void _checkResets() {
    final now = DateTime.now();
    bool changed = false;
    for (final t in tasks) {
      if (t.type == TaskType.repeating && t.isDone && t.nextResetAt != null) {
        if (now.isAfter(t.nextResetAt!)) {
          t.isDone = false;
          t.earnedXP = 0;
          t.nextResetAt = null;
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  List<Task> tasksForSkill(String id) {
    _checkResets();
    return tasks.where((t) => t.skillId == id).toList();
  }

  Skill? get selectedSkill {
    if (selectedSkillId == null) {
      return null;
    }
    try {
      return skills.firstWhere((s) => s.id == selectedSkillId);
    } catch (_) {
      return null;
    }
  }

  String? completeTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || task.isDone) {
      return null;
    }

    task.isDone = true;
    task.streak++;
    final earned = task.xpReward * task.streakMultiplier;
    task.earnedXP = earned;

    if (task.type == TaskType.repeating) {
      task.nextResetAt = _nextReset(
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    final skill = _skillById(task.skillId);
    if (skill != null) {
      skillUp = skill.addXP(earned);
    }

    _recordHistory(task, skill, earned, isCompletion: true);
    notifyListeners();

    if (globalUp > 0) {
      return '🎉 Уровень ${profile.level}!';
    }
    if (skillUp > 0 && skill != null) {
      return '⬆️ ${skill.name} → ур.${skill.level}';
    }
    return '+$earned XP';
  }

  void uncompleteTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || !task.isDone) {
      return;
    }
    final earned = task.earnedXP;
    task.isDone = false;
    task.streak = (task.streak - 1).clamp(0, 9999);
    task.earnedXP = 0;
    task.nextResetAt = null;
    profile.removeXP(earned);
    final skill = _skillById(task.skillId);
    skill?.removeXP(earned);
    _recordHistory(task, skill, earned, isCompletion: false);
    notifyListeners();
  }

  void _recordHistory(
    Task t,
    Skill? skill,
    int xp, {
    required bool isCompletion,
  }) {
    history.insert(
      0,
      HistoryEntry(
        id: uid(),
        taskTitle: t.title,
        skillId: t.skillId,
        skillName: skill?.name ?? '—',
        skillColor: skill?.color ?? const Color(0xFF8E8E93),
        skillIcon: skill?.icon ?? Icons.bolt,
        xp: xp,
        isCompletion: isCompletion,
        at: DateTime.now(),
      ),
    );
  }

  void selectSkill(String id) {
    selectedSkillId = (selectedSkillId == id) ? null : id;
    notifyListeners();
  }

  void addSkill(Skill s) {
    skills.add(s);
    notifyListeners();
  }

  void removeSkill(String id) {
    skills.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.skillId == id);
    if (selectedSkillId == id) {
      selectedSkillId = null;
    }
    notifyListeners();
  }

  void addTask(Task t) {
    tasks.add(t);
    notifyListeners();
  }

  void removeTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  Task? _taskById(String id) {
    try {
      return tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Skill? _skillById(String id) {
    try {
      return skills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
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
  bool shouldReclip(_RevealClipper old) =>
      old.progress != progress || old.corner != corner;
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════════════════════════

class RPGApp extends StatefulWidget {
  const RPGApp({super.key});
  @override
  State<RPGApp> createState() => _RPGAppState();
}

class _RPGAppState extends State<RPGApp> with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  final _repaintKey = GlobalKey();

  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;
  ui.Image? _overlayImage;
  Offset _revealCorner = Offset.zero;
  bool _revealing = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeInOutCubic,
    );
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
    if (_revealing) {
      return;
    }
    _revealing = true;

    ui.Image? frame;
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        frame = await boundary.toImage(
          pixelRatio: View.of(context).devicePixelRatio,
        );
      }
    } catch (_) {}

    if (!mounted) {
      _revealing = false;
      return;
    }

    final size = MediaQuery.of(context).size;
    _revealCorner = _state.isDark
        ? Offset(size.width, 0)
        : Offset(0, size.height);

    _state.isDark = !_state.isDark;
    setState(() {
      _overlayImage = frame;
    });

    if (frame != null) {
      _revealCtrl.value = 0;
      await _revealCtrl.forward();
    }

    setState(() {
      _overlayImage = null;
    });
    _revealing = false;
  }

  static ThemeData _buildTheme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF0F2F8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(surface: _surface(dark)),
    cardColor: _surface(dark),
    dividerColor: _border(dark),
  );

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
            if (_overlayImage != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _revealAnim,
                    builder: (_, _x) => ClipPath(
                      clipper: _RevealClipper(
                        progress: _revealAnim.value,
                        corner: _revealCorner,
                      ),
                      child: RawImage(
                        image: _overlayImage,
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppStateProvider extends InheritedWidget {
  final AppState state;
  const AppStateProvider({
    super.key,
    required this.state,
    required super.child,
  });
  static AppState of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<AppStateProvider>()!.state;
  @override
  bool updateShouldNotify(AppStateProvider old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainPage({super.key, required this.onToggleTheme});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<_XPBubble> _bubbles = [];

  void _onComplete(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeTask(taskId);
    if (msg == null) {
      return;
    }
    setState(() {
      _bubbles.add(
        _XPBubble(
          key: UniqueKey(),
          message: msg,
          position: pos,
          onDone: (k) =>
              setState(() => _bubbles.removeWhere((b) => b.key == k)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F13)
          : const Color(0xFFF0F2F8),
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(isDark: isDark, onToggle: widget.onToggleTheme, state: s),
              _ProfileBar(profile: s.profile, isDark: isDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 380, child: SkillsPanel(state: s)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TasksPanel(state: s, onComplete: _onComplete),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ..._bubbles,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppState state;
  const _TopBar({
    required this.isDark,
    required this.onToggle,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final surface = _surface(isDark);
    final textColor = _text(isDark);
    final sub = _subtext(isDark);

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 12),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF4A9EFF), size: 20),
          const SizedBox(width: 8),
          Text(
            'RPG To-Do List',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
          const Spacer(),
          _HoverIconBtn(
            icon: Icons.history,
            color: sub,
            onTap: () => showDialog(
              context: context,
              builder: (_) =>
                  HistoryDialog(history: state.history, isDark: isDark),
            ),
          ),
          const SizedBox(width: 4),
          _HoverIconBtn(
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            color: sub,
            onTap: onToggle,
          ),
          const SizedBox(width: 4),
          _HoverIconBtn(icon: Icons.settings, color: sub, onTap: () {}),
        ],
      ),
    );
  }
}

class _HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HoverIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<_HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<_HoverIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _h ? widget.color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon, color: widget.color, size: 20),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// HISTORY DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class HistoryDialog extends StatelessWidget {
  final List<HistoryEntry> history;
  final bool isDark;
  const HistoryDialog({super.key, required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = _surface(isDark);
    final txt = _text(isDark);
    final sub = _subtext(isDark);
    final bdr = _border(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  Text(
                    'Полная история персонажа',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book, color: sub, size: 38),
                          const SizedBox(height: 12),
                          Text(
                            'История пуста',
                            style: TextStyle(color: sub, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Выполни задачу — она появится здесь',
                            style: TextStyle(
                              color: sub.withAlpha(160),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      itemCount: history.length,
                      itemBuilder: (_, i) =>
                          _HistoryCard(entry: history[i], isDark: isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  const _HistoryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final c = e.skillColor;
    final isGreen = e.isCompletion;
    final accentBg = isGreen
        ? c.withAlpha(22)
        : const Color(0xFFFF3B30).withAlpha(18);
    final accentBorder = isGreen
        ? c.withAlpha(80)
        : const Color(0xFFFF3B30).withAlpha(60);
    final sub = _subtext(isDark);
    final txt = _text(isDark);

    final d = e.at;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}, '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.taskTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: txt,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isGreen ? 'Цель выполнена' : 'Выполнение отменено',
                    style: TextStyle(
                      color: sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(dateStr, style: TextStyle(color: sub, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildIcon(e.skillIcon, c, 13),
              const SizedBox(width: 5),
              Text('Навык: ', style: TextStyle(color: sub, fontSize: 12)),
              Text(
                e.skillName,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isGreen ? '+${e.xp} опыта' : '-${e.xp} опыта',
            style: TextStyle(
              color: isGreen ? c : const Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileBar extends StatelessWidget {
  final UserProfile profile;
  final bool isDark;
  const _ProfileBar({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = _surface(isDark);
    final textColor = _text(isDark);
    final sub = _subtext(isDark);

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LvlBadge(
                      level: profile.level,
                      color: const Color(0xFF4A9EFF),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _XPBar(
                        progress: profile.progress,
                        color: const Color(0xFF4A9EFF),
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${profile.xp} / ${profile.xpNeeded} XP',
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LvlBadge extends StatelessWidget {
  final int level;
  final Color color;
  const _LvlBadge({required this.level, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(
      'Уровень $level',
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED XP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _XPBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  const _XPBar({required this.progress, required this.color, this.height = 8});
  @override
  State<_XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<_XPBar> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(_XPBar old) {
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
    builder: (_, _x) => ClipRRect(
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
// SKILLS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class SkillsPanel extends StatelessWidget {
  final AppState state;
  const SkillsPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final surface = _surface(isDark);
    final textColor = _text(isDark);
    final sub = _subtext(isDark);
    final border = _border(isDark);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFF4A9EFF), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Навыки',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${state.skills.length})',
                  style: TextStyle(color: sub, fontSize: 13),
                ),
                const Spacer(),
                _SmallBtn(
                  label: 'Добавить',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  onTap: () => _addSkillDialog(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.selectedSkillId == null
                    ? 'Выберите навык для просмотра задач'
                    : 'Задачи: ${state.selectedSkill?.name ?? ""}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ),
          ),
          Container(height: 1, color: border),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: state.skills.length,
              separatorBuilder: (_, _x) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: border,
              ),
              itemBuilder: (ctx, i) {
                final sk = state.skills[i];
                return _SkillCard(
                  skill: sk,
                  taskCount: state
                      .tasksForSkill(sk.id)
                      .where((t) => !t.isDone)
                      .length,
                  isSelected: state.selectedSkillId == sk.id,
                  isDark: isDark,
                  onTap: () => state.selectSkill(sk.id),
                  onEdit: () => _editSkillDialog(context, sk),
                  onDelete: () => state.removeSkill(sk.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addSkillDialog(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
      onSave: (name, goal, checklist, color, icon) => state.addSkill(
        Skill(
          id: uid(),
          name: name,
          goal: goal,
          color: color,
          icon: icon,
          checklist: checklist,
        ),
      ),
    ),
  );

  void _editSkillDialog(BuildContext ctx, Skill sk) => showDialog(
    context: ctx,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
      existing: sk,
      onSave: (name, goal, checklist, color, icon) {
        sk.name = name;
        sk.goal = goal;
        sk.checklist = checklist;
        sk.color = color;
        sk.icon = icon;
        state.refresh();
      },
    ),
  );
}

class _SkillCard extends StatefulWidget {
  final Skill skill;
  final int taskCount;
  final bool isSelected, isDark;
  final VoidCallback onTap, onEdit, onDelete;
  const _SkillCard({
    required this.skill,
    required this.taskCount,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final sk = widget.skill;
    final isDark = widget.isDark;
    final textColor = _text(isDark);
    final sub = _subtext(isDark);

    Color bg = Colors.transparent;
    if (widget.isSelected) {
      bg = sk.color.withAlpha(22);
    } else if (_h) {
      bg = isDark ? const Color(0xFF22222E) : const Color(0xFFF0F0F8);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.isSelected
                ? Border.all(color: sk.color.withAlpha(100))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sk.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: _buildIcon(sk.icon, sk.color, 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sk.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _LvlBadge(level: sk.level, color: sk.color),
                        if (widget.taskCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: sk.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.taskCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: _XPBar(
                            progress: sk.progress,
                            color: sk.color,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${sk.xp}/${sk.xpNeeded}',
                          style: TextStyle(color: sub, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_h || widget.isSelected) ? 48 : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 48,
                    child: Row(
                      children: [
                        _MiniBtn(
                          icon: Icons.edit,
                          color: sub,
                          onTap: widget.onEdit,
                        ),
                        _MiniBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFFF3B30),
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatelessWidget {
  final AppState state;
  final Function(String id, Offset pos) onComplete;
  const TasksPanel({super.key, required this.state, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final surface = _surface(isDark);
    final textColor = _text(isDark);
    final sub = _subtext(isDark);
    final border = _border(isDark);
    final skill = state.selectedSkill;

    if (skill == null) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: sub, size: 30),
              const SizedBox(height: 12),
              Text(
                'Выберите навык',
                style: TextStyle(
                  color: sub,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Задачи откроются здесь',
                style: TextStyle(color: sub.withAlpha(160), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final allTasks = state.tasksForSkill(skill.id);
    final active = allTasks.where((t) => !t.isDone).toList();
    final done = allTasks.where((t) => t.isDone).toList();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: skill.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: _buildIcon(skill.icon, skill.color, 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      if (skill.goal.isNotEmpty)
                        Text(
                          skill.goal,
                          style: TextStyle(color: sub, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _SmallBtn(
                  label: ' Задача',
                  icon: Icons.add,
                  color: skill.color,
                  onTap: () => _addTask(context, skill),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _XPBar(
                    progress: skill.progress,
                    color: skill.color,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${skill.xp} / ${skill.xpNeeded} XP  •  Ур.${skill.level}',
                  style: TextStyle(color: sub, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(height: 1, color: border),
          Expanded(
            child: allTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task, color: sub, size: 38),
                        const SizedBox(height: 10),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            color: sub,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Нажмите « Задача»',
                          style: TextStyle(
                            color: sub.withAlpha(150),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ...active.map(
                        (t) => _TaskTile(
                          task: t,
                          isDark: isDark,
                          skillColor: skill.color,
                          onToggle: (pos) => onComplete(t.id, pos),
                          onUncomplete: () => state.uncompleteTask(t.id),
                          onDelete: () => state.removeTask(t.id),
                          onEdit: () => _editTask(context, skill, t),
                        ),
                      ),
                      if (done.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: sub,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Выполнено сегодня (${done.length})',
                                style: TextStyle(
                                  color: sub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...done.map(
                          (t) => _TaskTile(
                            task: t,
                            isDark: isDark,
                            skillColor: skill.color,
                            onToggle: (_) => state.uncompleteTask(t.id),
                            onUncomplete: () => state.uncompleteTask(t.id),
                            onDelete: () => state.removeTask(t.id),
                            onEdit: () => _editTask(context, skill, t),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext ctx, Skill skill) => showDialog(
    context: ctx,
    builder: (_) => AddTaskDialog(
      isDark: state.isDark,
      skillColor: skill.color,
      onSave: (title, xp, type, freq, customDays) => state.addTask(
        Task(
          id: uid(),
          title: title,
          skillId: skill.id,
          xpReward: xp,
          type: type,
          repeatFrequency: freq,
          repeatCustomDays: customDays,
        ),
      ),
    ),
  );

  void _editTask(BuildContext ctx, Skill skill, Task task) => showDialog(
    context: ctx,
    builder: (_) => AddTaskDialog(
      isDark: state.isDark,
      skillColor: skill.color,
      existing: task,
      onSave: (title, xp, type, freq, customDays) {
        task.title = title;
        task.xpReward = xp;
        task.type = type;
        task.repeatFrequency = freq;
        task.repeatCustomDays = customDays;
        state.refresh();
      },
    ),
  );
}

// ─── Task Tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final Function(Offset) onToggle;
  final VoidCallback onUncomplete, onDelete, onEdit;
  const _TaskTile({
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.onToggle,
    required this.onUncomplete,
    required this.onDelete,
    required this.onEdit,
  });
  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  final _cbKey = GlobalKey();
  bool _h = false;

  String _formatReset(DateTime? dt) {
    if (dt == null) {
      return '';
    }
    return 'Обновится ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} в 03:00';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDark = widget.isDark;
    final textColor = _text(isDark);
    final sub = _subtext(isDark);
    final tileBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA);
    final border = _border(isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _h
              ? (isDark ? const Color(0xFF1E1E2A) : const Color(0xFFECECF8))
              : tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                key: _cbKey,
                onTapUp: (d) {
                  if (t.isDone) {
                    widget.onUncomplete();
                  } else {
                    final box =
                        _cbKey.currentContext!.findRenderObject() as RenderBox;
                    widget.onToggle(box.localToGlobal(Offset.zero));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.isDone ? widget.skillColor : sub,
                      width: 2,
                    ),
                    color: t.isDone ? widget.skillColor : Colors.transparent,
                  ),
                  child: t.isDone
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: t.isDone ? sub : textColor,
                        decoration: t.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: sub,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: _typeLabel[t.type]!,
                          color: _typeColor[t.type]!,
                        ),
                        _Badge(
                          icon: Icons.auto_awesome,
                          label: t.isDone
                              ? '-${t.earnedXP} XP'
                              : '+${t.xpReward * t.streakMultiplier} XP',
                          color: t.isDone ? sub : const Color(0xFF4A9EFF),
                        ),
                        if (t.streakMultiplier > 1 && !t.isDone)
                          _Badge(
                            icon: Icons.local_fire_department,
                            label: '×${t.streakMultiplier}',
                            color: const Color(0xFFFF9500),
                          ),
                        if (t.streak > 0)
                          Text(
                            '${t.streak} д.',
                            style: TextStyle(color: sub, fontSize: 11),
                          ),
                        if (t.type == TaskType.repeating) ...[
                          _Badge(
                            icon: Icons.repeat,
                            label: _freqLabel[t.repeatFrequency]!,
                            color: const Color(0xFF4A9EFF),
                          ),
                          if (t.isDone && t.nextResetAt != null)
                            Text(
                              _formatReset(t.nextResetAt),
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _h ? 44 : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniBtn(
                          icon: Icons.edit,
                          color: sub,
                          onTap: widget.onEdit,
                        ),
                        _MiniBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFFF3B30),
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});
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

class _XPBubble extends StatefulWidget {
  final String message;
  final Offset position;
  final Function(Key?) onDone;
  const _XPBubble({
    super.key,
    required this.message,
    required this.position,
    required this.onDone,
  });
  @override
  State<_XPBubble> createState() => _XPBubbleState();
}

class _XPBubbleState extends State<_XPBubble>
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
    builder: (_, _x) => Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy + _y.value,
      child: Opacity(
        opacity: _o.value,
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
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD SKILL DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

const _kIcons = <IconData>[
  Icons.fitness_center,
  Icons.code,
  Icons.sports_esports,
  Icons.menu_book,
  Icons.music_note,
  Icons.palette,
  Icons.language,
  Icons.science,
  Icons.directions_run,
  Icons.psychology,
  Icons.attach_money,
  Icons.business_center,
  Icons.camera_alt,
  Icons.flight,
  Icons.favorite,
  Icons.emoji_events,
  Icons.school,
  Icons.sports_soccer,
  Icons.restaurant,
  Icons.local_hospital,
  Icons.trending_up,
  Icons.self_improvement,
  Icons.star,
  Icons.public,
];

const _kEmojis = <String>[
  '🏠',
  '🛒',
  '💼',
  '🍕',
  '🏋️‍♂️',
  '🎨',
  '🎬',
  '💡',
  '🚀',
  '🐱',
];

const _kColors = <Color>[
  Color(0xFF4A9EFF),
  Color(0xFF34C759),
  Color(0xFFFF9500),
  Color(0xFFFF3B30),
  Color(0xFFFF2D55),
  Color(0xFFAF52DE),
  Color(0xFF5AC8FA),
  Color(0xFFFFCC00),
  Color(0xFF5856D6),
  Color(0xFF8E8E93),
];

class AddSkillDialog extends StatefulWidget {
  final bool isDark;
  final Skill? existing;
  final Function(
    String name,
    String goal,
    List<String> checklist,
    Color color,
    dynamic icon,
  )
  onSave;
  const AddSkillDialog({
    super.key,
    required this.isDark,
    this.existing,
    required this.onSave,
  });
  @override
  State<AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _checkCtrl = TextEditingController();
  final List<String> _items = [];
  Color _color = const Color(0xFF4A9EFF);
  dynamic _icon = Icons.fitness_center;

  @override
  void initState() {
    super.initState();
    if (widget.existing case final ex?) {
      _nameCtrl.text = ex.name;
      _goalCtrl.text = ex.goal;
      _items.addAll(ex.checklist);
      _color = ex.color;
      _icon = ex.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = _surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = _text(isDark);
    final sub = _subtext(isDark);
    final bdr = _border(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DlgHeader(
                title: widget.existing != null
                    ? 'Редактировать навык'
                    : 'Новый навык',
                textColor: txt,
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _color.withAlpha(35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: _buildIcon(_icon, _color, 30)),
                ),
              ),
              const SizedBox(height: 16),
              _DlgField(
                label: 'Название навыка',
                ctrl: _nameCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 10),
              _DlgField(
                label: 'Цель',
                ctrl: _goalCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
                min: 2,
              ),
              const SizedBox(height: 14),
              _SubLbl('Иконка', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [..._kIcons, ..._kEmojis].map((ic) {
                  final sel = ic == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: sel ? _color.withAlpha(50) : fBg,
                        borderRadius: BorderRadius.circular(8),
                        border: sel
                            ? Border.all(color: _color, width: 2)
                            : Border.all(color: bdr),
                      ),
                      child: Center(
                        child: _buildIcon(ic, sel ? _color : sub, 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _SubLbl('Цвет', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kColors.map((c) {
                  final sel = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: c.withAlpha(130),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _SubLbl('Чек-лист', sub),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_box, size: 15, color: sub),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(color: txt, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _items.removeAt(e.key)),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checkCtrl,
                      style: TextStyle(color: txt, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '+ Добавить пункт',
                        hintStyle: TextStyle(color: sub, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addItem,
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF4A9EFF),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _DlgActions(
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem() {
    final t = _checkCtrl.text.trim();
    if (t.isNotEmpty) {
      setState(() {
        _items.add(t);
        _checkCtrl.clear();
      });
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      return;
    }
    widget.onSave(_nameCtrl.text.trim(), _goalCtrl.text, _items, _color, _icon);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD TASK DIALOG  — с частотой для повторяющихся + предупреждение XP
// ═══════════════════════════════════════════════════════════════════════════════

class AddTaskDialog extends StatefulWidget {
  final bool isDark;
  final Color skillColor;
  final Task? existing;
  final Function(
    String title,
    int xp,
    TaskType type,
    RepeatFrequency freq,
    int customDays,
  )
  onSave;
  const AddTaskDialog({
    super.key,
    required this.isDark,
    required this.skillColor,
    this.existing,
    required this.onSave,
  });
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _customCtrl = TextEditingController(text: '1');
  int _xp = 20;
  TaskType _type = TaskType.shortTerm;
  RepeatFrequency _freq = RepeatFrequency.daily;

  int get _softCap => _typeSoftCap[_type]!;
  bool get _overCap => _xp > _softCap;

  @override
  void initState() {
    super.initState();
    if (widget.existing case final ex?) {
      _titleCtrl.text = ex.title;
      _xp = ex.xpReward;
      _type = ex.type;
      _freq = ex.repeatFrequency;
      _customCtrl.text = '${ex.repeatCustomDays}';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = _surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = _text(isDark);
    final sub = _subtext(isDark);
    final bdr = _border(isDark);
    final c = widget.skillColor;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DlgHeader(
                title: widget.existing != null
                    ? 'Редактировать задачу'
                    : 'Новая задача',
                textColor: txt,
              ),
              const SizedBox(height: 16),
              _DlgField(
                label: 'Название задачи',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 16),

              // XP
              Row(
                children: [
                  _SubLbl('Награда XP', sub),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_xp XP',
                      style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _xp.toDouble(),
                min: 5,
                max: 1000,
                divisions: 199,
                activeColor: c,
                inactiveColor: c.withAlpha(40),
                onChanged: (v) => setState(() => _xp = v.round()),
              ),
              // Предупреждение
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _overCap
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF9500).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF9500),
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Не рекомендуется: лимит для «${_typeLabel[_type]}» — $_softCap XP.',
                                style: const TextStyle(
                                  color: Color(0xFFFF9500),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Тип
              _SubLbl('Тип задачи', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskType.values.map((t) {
                  final sel = _type == t;
                  final tc = _typeColor[t]!;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? tc.withAlpha(40) : fBg,
                        borderRadius: BorderRadius.circular(8),
                        border: sel
                            ? Border.all(color: tc)
                            : Border.all(color: bdr),
                      ),
                      child: Text(
                        _typeLabel[t]!,
                        style: TextStyle(
                          color: sel ? tc : sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Частота — только для повторяющихся
              if (_type == TaskType.repeating) ...[
                const SizedBox(height: 16),
                _SubLbl('Частота выполнения', sub),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bdr),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RepeatFrequency.values.map((f) {
                          final sel = _freq == f;
                          return GestureDetector(
                            onTap: () => setState(() => _freq = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 130),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF4A9EFF).withAlpha(40)
                                    : (isDark
                                          ? const Color(0xFF2A2A35)
                                          : const Color(0xFFEAEAF0)),
                                borderRadius: BorderRadius.circular(20),
                                border: sel
                                    ? Border.all(color: const Color(0xFF4A9EFF))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (f == RepeatFrequency.daily ||
                                      f == RepeatFrequency.custom)
                                    Icon(
                                      Icons.repeat,
                                      size: 12,
                                      color: sel
                                          ? const Color(0xFF4A9EFF)
                                          : sub,
                                    ),
                                  if (f == RepeatFrequency.daily ||
                                      f == RepeatFrequency.custom)
                                    const SizedBox(width: 4),
                                  Text(
                                    _freqLabel[f]!,
                                    style: TextStyle(
                                      color: sel
                                          ? const Color(0xFF4A9EFF)
                                          : sub,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_freq == RepeatFrequency.custom) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Каждые',
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _customCtrl,
                                style: TextStyle(color: txt, fontSize: 13),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: bdr),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A9EFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'дней',
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Задача обновится в 03:00 через ${_freqDays(_freq, int.tryParse(_customCtrl.text) ?? 1)} дн.',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              _DlgActions(
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      return;
    }
    final customDays = int.tryParse(_customCtrl.text) ?? 1;
    widget.onSave(_titleCtrl.text.trim(), _xp, _type, _freq, customDays);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: 17, color: color),
    ),
  );
}

class _DlgHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _DlgHeader({required this.title, required this.textColor});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Color(0xFF8E8E93), size: 22),
      ),
    ],
  );
}

class _DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color fBg, txt, sub, bdr;
  final int min;
  const _DlgField({
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
      _SubLbl(label, sub),
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

class _DlgActions extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  const _DlgActions({required this.onCancel, required this.onSave});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      GestureDetector(
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
      GestureDetector(
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

class _SubLbl extends StatelessWidget {
  final String text;
  final Color color;
  const _SubLbl(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}
