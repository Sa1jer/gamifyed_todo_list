import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ID GENERATOR
// ═══════════════════════════════════════════════════════════════════════════════

int _nextId = 0;
String uid() {
  final micros = DateTime.now().microsecondsSinceEpoch;
  return '${micros}_${++_nextId}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

// ═══════════════════════════════════════════════════════════════════════════════
// XP PROGRESSION  (linear-stepped)
// ═══════════════════════════════════════════════════════════════════════════════

int xpForLevel(int level) {
  if (level <= 3) return 1000;
  if (level <= 7) return 2000;
  if (level <= 10) return 3000;
  return 4000;
}

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Color _darken(Color c, [double factor = 0.22]) => Color.fromARGB(
  (c.a * 255.0).round(),
  ((c.r * 255.0) * (1 - factor)).round().clamp(0, 255),
  ((c.g * 255.0) * (1 - factor)).round().clamp(0, 255),
  ((c.b * 255.0) * (1 - factor)).round().clamp(0, 255),
);
// Export for other files
Color darken(Color c, [double factor = 0.22]) => _darken(c, factor);

Color surface(bool d) => d ? const Color(0xFF1A1A24) : Colors.white;
Color textColor(bool d) =>
    d ? const Color(0xFFEEEEF4) : const Color(0xFF0D0D14);
Color subtext(bool d) => d ? const Color(0xFF8E8E93) : const Color(0xFF555560);
Color borderColor(bool d) =>
    d ? const Color(0xFF2A2A35) : const Color(0xFFD8D8E4);

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum TaskType { repeating, shortTerm, midTerm, longTerm }

const typeLabel = {
  TaskType.repeating: 'Повторяющаяся',
  TaskType.shortTerm: 'Краткосрочная',
  TaskType.midTerm: 'Среднесрочная',
  TaskType.longTerm: 'Долгосрочная',
};
const typeColor = {
  TaskType.repeating: Color(0xFF4A9EFF),
  TaskType.shortTerm: Color(0xFF34C759),
  TaskType.midTerm: Color(0xFFFF9500),
  TaskType.longTerm: Color(0xFFFF3B30),
};
const typeSoftCap = {
  TaskType.repeating: 100,
  TaskType.shortTerm: 200,
  TaskType.midTerm: 500,
  TaskType.longTerm: 1000,
};

enum RepeatFrequency { daily, every3Days, weekly, biweekly, monthly, custom }

const freqLabel = {
  RepeatFrequency.daily: '1 раз за 1 день',
  RepeatFrequency.every3Days: 'раз в 3 дня',
  RepeatFrequency.weekly: 'раз в неделю',
  RepeatFrequency.biweekly: 'раз в 2 недели',
  RepeatFrequency.monthly: 'раз в месяц',
  RepeatFrequency.custom: 'персональная',
};

int freqDays(RepeatFrequency f, int custom) => switch (f) {
  RepeatFrequency.daily => 1,
  RepeatFrequency.every3Days => 3,
  RepeatFrequency.weekly => 7,
  RepeatFrequency.biweekly => 14,
  RepeatFrequency.monthly => 30,
  RepeatFrequency.custom => custom < 1 ? 1 : custom,
};

DateTime nextReset(RepeatFrequency freq, int customDays) {
  return nextResetFrom(DateTime.now(), freq, customDays);
}

DateTime nextResetFrom(DateTime from, RepeatFrequency freq, int customDays) {
  final d = from.add(Duration(days: freqDays(freq, customDays)));
  return DateTime(d.year, d.month, d.day, 3, 0, 0);
}

DateTime dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatDateTime(DateTime dateTime) {
  return '${_twoDigits(dateTime.day)}.${_twoDigits(dateTime.month)}.'
      '${dateTime.year}, ${_twoDigits(dateTime.hour)}:'
      '${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
}

String formatShortDate(DateTime dateTime) {
  return '${_twoDigits(dateTime.day)}.${_twoDigits(dateTime.month)}.'
      '${dateTime.year}';
}

String formatTime(DateTime dateTime) {
  return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
}

String formatResetLabel(DateTime? dateTime) {
  if (dateTime == null) return '';
  return 'Обновится ${_twoDigits(dateTime.day)}.${_twoDigits(dateTime.month)} '
      'в ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// ICON LISTS
// FIX 1.0.5: Moved flight, favorite, emoji_events, restaurant, local_hospital
//            from primary → extra list.
// ═══════════════════════════════════════════════════════════════════════════════

const kIconsPrimary = <IconData>[
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
  Icons.school,
  Icons.sports_soccer,
];

const kIconsExtra = <IconData>[
  // moved from primary
  Icons.flight,
  Icons.favorite,
  Icons.emoji_events,
  Icons.restaurant,
  Icons.local_hospital,
  // original extra
  Icons.trending_up,
  Icons.self_improvement,
  Icons.star,
  Icons.public,
  Icons.home,
  Icons.shopping_cart,
  Icons.pets,
  Icons.nature,
  Icons.sports_tennis,
  Icons.sports_basketball,
  Icons.directions_bike,
  Icons.pool,
  Icons.laptop_mac,
  Icons.phone_android,
  Icons.headphones,
  Icons.tv,
  Icons.local_florist,
  Icons.eco,
  Icons.park,
  Icons.beach_access,
  Icons.spa,
  Icons.hiking,
  Icons.bolt,
  Icons.water_drop,
  Icons.wb_sunny,
  Icons.nightlight_round,
  Icons.cloud,
  Icons.recycling,
  Icons.biotech,
  Icons.agriculture,
  Icons.volunteer_activism,
  Icons.construction,
  Icons.auto_fix_high,
  Icons.brush,
  Icons.calculate,
  Icons.translate,
  Icons.history_edu,
  Icons.sports_martial_arts,
  Icons.sailing,
  Icons.snowboarding,
];

const kColors = <Color>[
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
