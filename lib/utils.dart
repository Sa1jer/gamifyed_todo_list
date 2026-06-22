import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

const String kAppVersionLabel = 'v1.3.42+1';

// ═══════════════════════════════════════════════════════════════════════════════
// ID GENERATOR
// ═══════════════════════════════════════════════════════════════════════════════

final math.Random _uidRandom = math.Random.secure();
int _nextId = 0;
String uid() {
  final micros = DateTime.now().microsecondsSinceEpoch;
  final random = _uidRandom
      .nextInt(0xFFFFFFFF)
      .toRadixString(16)
      .padLeft(8, '0');
  return '${micros}_${random}_${++_nextId}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

bool hasSupportedImageMagicBytes(Uint8List bytes) {
  final isPng =
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
  final isJpeg =
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
  return isPng || isJpeg;
}

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
// RANKS
// ═══════════════════════════════════════════════════════════════════════════════

class RankInfo {
  final String code;
  final String label;
  final Color color;
  final int minLevel;

  const RankInfo({
    required this.code,
    required this.label,
    required this.color,
    required this.minLevel,
  });
}

const profileRankTiers = <RankInfo>[
  RankInfo(code: 'E', label: 'E-rank', color: Color(0xFF8E8E93), minLevel: 1),
  RankInfo(code: 'D', label: 'D-rank', color: Color(0xFF4A9EFF), minLevel: 3),
  RankInfo(code: 'C', label: 'C-rank', color: Color(0xFF34C759), minLevel: 5),
  RankInfo(code: 'B', label: 'B-rank', color: Color(0xFFFF9500), minLevel: 7),
  RankInfo(code: 'A', label: 'A-rank', color: Color(0xFFFF2D55), minLevel: 9),
  RankInfo(code: 'S', label: 'S-rank', color: Color(0xFFFFCC00), minLevel: 11),
];

const skillRankTiers = <RankInfo>[
  RankInfo(
    code: 'novice',
    label: 'Новичок',
    color: Color(0xFF8E8E93),
    minLevel: 1,
  ),
  RankInfo(
    code: 'apprentice',
    label: 'Ученик',
    color: Color(0xFF4A9EFF),
    minLevel: 3,
  ),
  RankInfo(
    code: 'practitioner',
    label: 'Практик',
    color: Color(0xFF34C759),
    minLevel: 5,
  ),
  RankInfo(
    code: 'specialist',
    label: 'Специалист',
    color: Color(0xFFFF9500),
    minLevel: 7,
  ),
  RankInfo(
    code: 'master',
    label: 'Мастер',
    color: Color(0xFFAF52DE),
    minLevel: 9,
  ),
  RankInfo(
    code: 'legend',
    label: 'Легенда',
    color: Color(0xFFFFCC00),
    minLevel: 11,
  ),
];

RankInfo _rankForLevel(List<RankInfo> tiers, int level) {
  final normalizedLevel = level < 1 ? 1 : level;
  return tiers.lastWhere((tier) => normalizedLevel >= tier.minLevel);
}

RankInfo? _nextRankForLevel(List<RankInfo> tiers, int level) {
  final current = _rankForLevel(tiers, level);
  for (final tier in tiers) {
    if (tier.minLevel > current.minLevel) {
      return tier;
    }
  }
  return null;
}

RankInfo profileRankForLevel(int level) =>
    _rankForLevel(profileRankTiers, level);

RankInfo? nextProfileRankForLevel(int level) =>
    _nextRankForLevel(profileRankTiers, level);

RankInfo skillRankForLevel(int level) => _rankForLevel(skillRankTiers, level);

RankInfo? nextSkillRankForLevel(int level) =>
    _nextRankForLevel(skillRankTiers, level);

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum TaskType { repeating, shortTerm, midTerm, longTerm }

const typeLabel = {
  TaskType.repeating: 'Привычка',
  TaskType.shortTerm: 'Разово',
  TaskType.midTerm: 'Проект',
  TaskType.longTerm: 'Большая цель',
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

int multiplierForStreak(int streak) {
  if (streak < 2) return 1;
  if (streak >= 14) return 4;
  if (streak >= 7) return 3;
  return 2;
}

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
  Color(0xFFFF3B30),
  Color(0xFFFF6B2C),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFFB8E986),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF5AC8FA),
  Color(0xFF4A9EFF),
  Color(0xFF5856D6),
  Color(0xFFAF52DE),
  Color(0xFF8E8E93),
];
