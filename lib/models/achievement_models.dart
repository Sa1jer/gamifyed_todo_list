import 'package:flutter/material.dart';

class AchievementDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class Achievement {
  final String id;
  DateTime? unlockedAt;
  AchievementDef? def;

  Achievement({required this.id, this.unlockedAt});

  bool get isUnlocked => unlockedAt != null;
}

const achievementDefinitions = <AchievementDef>[
  AchievementDef(
    id: 'first_task',
    name: 'Первая победа',
    description: 'Выполни свой первый квест',
    icon: Icons.star_border,
    color: Color(0xFF4A9EFF),
  ),
  AchievementDef(
    id: 'streak_7',
    name: 'Недельная серия',
    description: '7 дней подряд выполняй повторяющиеся квесты',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF9500),
  ),
  AchievementDef(
    id: 'streak_30',
    name: 'Месячная серия',
    description: '30 дней подряд выполняй повторяющиеся квесты',
    icon: Icons.whatshot,
    color: Color(0xFFFF3B30),
  ),
  AchievementDef(
    id: 'tasks_100',
    name: 'Столетие',
    description: 'Выполни 100 квестов',
    icon: Icons.emoji_events,
    color: Color(0xFFFFCC00),
  ),
  AchievementDef(
    id: 'tasks_500',
    name: 'Полтысячи',
    description: 'Выполни 500 квестов',
    icon: Icons.military_tech,
    color: Color(0xFFAF52DE),
  ),
  AchievementDef(
    id: 'level_5',
    name: 'Подмастерье',
    description: 'Достигни 5 уровня',
    icon: Icons.trending_up,
    color: Color(0xFF34C759),
  ),
  AchievementDef(
    id: 'level_10',
    name: 'Мастер',
    description: 'Достигни 10 уровня',
    icon: Icons.workspace_premium,
    color: Color(0xFF5856D6),
  ),
  AchievementDef(
    id: 'skills_3',
    name: 'Три пути',
    description: 'Создай 3 навыка',
    icon: Icons.bolt,
    color: Color(0xFF5AC8FA),
  ),
  AchievementDef(
    id: 'first_boss',
    name: 'Первое сопротивление',
    description: 'Преодолей первое сопротивление',
    icon: Icons.shield,
    color: Color(0xFFFF2D55),
  ),
  AchievementDef(
    id: 'all_checklist',
    name: 'Перфекционист',
    description: 'Заверши все чеклисты навыка',
    icon: Icons.checklist,
    color: Color(0xFF8E8E93),
  ),
];
