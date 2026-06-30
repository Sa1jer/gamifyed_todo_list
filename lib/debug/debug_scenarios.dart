import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

enum DebugScenarioDanger { safe, overwrite }

class DebugScenarioDef {
  final String id;
  final String title;
  final String description;
  final DebugScenarioDanger dangerLevel;
  final bool resetBestStreak;
  final void Function(AppState state) apply;

  const DebugScenarioDef({
    required this.id,
    required this.title,
    required this.description,
    required this.dangerLevel,
    required this.apply,
    this.resetBestStreak = false,
  });
}

const debugScenarioFreshUser = DebugScenarioDef(
  id: 'fresh_user',
  title: 'Новый пользователь',
  description:
      'Очищает навыки, квесты, историю, трофеи, эффекты и сопротивление.',
  dangerLevel: DebugScenarioDanger.overwrite,
  resetBestStreak: true,
  apply: _applyFreshUser,
);

const debugScenarioStreak7 = DebugScenarioDef(
  id: 'streak_7',
  title: 'Стрик 7 дней',
  description:
      'Создаёт repeating-квест со streak 7 и открывает достижение серии.',
  dangerLevel: DebugScenarioDanger.overwrite,
  resetBestStreak: true,
  apply: _applyStreak7,
);

const debugScenarioAllAchievements = DebugScenarioDef(
  id: 'all_achievements_unlocked',
  title: 'Все достижения открыты',
  description: 'Разблокирует все текущие achievement definitions.',
  dangerLevel: DebugScenarioDanger.safe,
  apply: _applyAllAchievementsUnlocked,
);

const debugScenarioEpicChest = DebugScenarioDef(
  id: 'epic_chest_pending',
  title: 'Epic-сундук ожидает открытия',
  description: 'Добавляет unopened epic chest для проверки трофеев.',
  dangerLevel: DebugScenarioDanger.safe,
  apply: _applyEpicChestPending,
);

const debugScenarioBossDefeated = DebugScenarioDef(
  id: 'boss_defeated',
  title: 'Сопротивление побеждено',
  description: 'Создаёт defeated resistance event и трофей победы.',
  dangerLevel: DebugScenarioDanger.safe,
  apply: _applyBossDefeated,
);

const debugScenarioActiveBuffs = DebugScenarioDef(
  id: 'active_effects',
  title: 'Активные эффекты',
  description: 'Добавляет несколько активных пассивных эффектов.',
  dangerLevel: DebugScenarioDanger.safe,
  apply: _applyActiveEffects,
);

const debugScenarios = <DebugScenarioDef>[
  debugScenarioFreshUser,
  debugScenarioStreak7,
  debugScenarioAllAchievements,
  debugScenarioEpicChest,
  debugScenarioBossDefeated,
  debugScenarioActiveBuffs,
];

void _applyFreshUser(AppState state) {
  _clearWorld(state);
  state.profile = UserProfile(name: 'Your Name');
  state.resetFirstRunTutorial();
}

void _applyStreak7(AppState state) {
  _clearWorld(state);
  final skill = _ensureDebugSkill(state);
  final now = DateTime.now();
  final quest = Task(
    id: uid(),
    title: 'Поддержать debug-серию',
    skillId: skill.id,
    xpReward: 20,
    type: TaskType.repeating,
    streak: 7,
    repeatFrequency: RepeatFrequency.daily,
    minimumAction: 'Сделать один маленький повтор',
    nextResetAt: nextResetFrom(now, RepeatFrequency.daily, 1),
    updatedAt: now,
  );
  state.tasks.add(quest);
  _setAchievement(state, 'streak_7', true);
  state.selectedSkillId = skill.id;
}

void _applyAllAchievementsUnlocked(AppState state) {
  _ensureAchievements(state);
  final now = DateTime.now();
  for (final achievement in state.achievements) {
    achievement.unlockedAt ??= now;
  }
}

void _applyEpicChestPending(AppState state) {
  state.rewardChests.add(
    RewardChest(
      id: uid(),
      title: 'Debug epic-сундук',
      description: 'Тестовый эпический сундук из Debug Admin.',
      rarity: RewardRarity.epic,
      sourceKey: 'debug:epic_chest:${uid()}',
      unlockedAt: DateTime.now(),
    ),
  );
}

void _applyBossDefeated(AppState state) {
  final skill = _ensureDebugSkill(state);
  final now = DateTime.now();
  if (skill.treeNodes.isNotEmpty) {
    skill.treeNodes.first.isMastered = true;
    skill.treeNodes.first.masteredAt = now;
  }
  state.tasks.add(
    Task(
      id: uid(),
      title: 'Закрыть debug-сопротивление',
      skillId: skill.id,
      xpReward: 30,
      type: TaskType.shortTerm,
      isDone: true,
      earnedXP: 30,
      lastCompletedAt: now,
      priority: Priority.high,
      updatedAt: now,
    ),
  );
  state.bosses.add(
    Boss(
      id: uid(),
      title: 'Debug сопротивление',
      skillId: skill.id,
      hp: 0,
      maxHp: 100,
      targetStreak: 7,
      currentStreak: 7,
      isDefeated: true,
      defeatedAt: now,
    ),
  );
  _setAchievement(state, 'first_boss', true);
  state.rewardChests.add(
    RewardChest(
      id: uid(),
      title: 'Debug сундук победы',
      description: 'Трофей за тестовое преодоление сопротивления.',
      rarity: RewardRarity.rare,
      sourceKey: 'debug:boss_defeated:${uid()}',
      skillId: skill.id,
      unlockedAt: now,
    ),
  );
}

void _applyActiveEffects(AppState state) {
  final skill = _ensureDebugSkill(state);
  final now = DateTime.now();
  final expiresAt = now.add(const Duration(hours: 24));
  state.buffs.addAll([
    Buff(
      id: uid(),
      type: BuffType.nextQuestXpBoost,
      title: 'Debug импульс',
      description: 'Следующий квест даст +15% XP.',
      bonusPercent: 15,
      charges: 1,
      sourceKey: 'debug:next_quest_effect:${uid()}',
      createdAt: now,
      expiresAt: expiresAt,
    ),
    Buff(
      id: uid(),
      type: BuffType.skillFocusXpBoost,
      title: 'Debug фокус навыка',
      description: 'Следующий квест выбранного навыка даст +25% XP.',
      bonusPercent: 25,
      charges: 1,
      skillId: skill.id,
      sourceKey: 'debug:skill_focus_effect:${uid()}',
      createdAt: now,
      expiresAt: expiresAt,
    ),
  ]);
}

void _clearWorld(AppState state) {
  state.selectedSkillId = null;
  state.skills.clear();
  state.tasks.clear();
  state.history.clear();
  state.rewardChests.clear();
  state.buffs.clear();
  state.bosses.clear();
  state.weeklyGoals.clear();
  state.todayStats = null;
  _resetAchievements(state);
}

Skill _ensureDebugSkill(AppState state) {
  if (state.roadmapSkills.isNotEmpty) return state.roadmapSkills.first;
  final stageId = uid();
  final skill = Skill(
    id: uid(),
    name: 'Debug навык',
    goal: 'Проверить состояние приложения',
    color: const Color(0xFFFF9500),
    icon: Icons.bug_report_outlined,
    treeNodes: [
      SkillTreeNode(
        id: stageId,
        title: 'Debug этап',
        description: 'Тестовая ступень для simulator-сценариев.',
        xpReward: 30,
        requiredQuestCompletions: 3,
      ),
    ],
  );
  state.skills.add(skill);
  state.selectedSkillId = skill.id;
  return skill;
}

void _resetAchievements(AppState state) {
  state.achievements
    ..clear()
    ..addAll(
      achievementDefinitions.map((def) => Achievement(id: def.id)..def = def),
    );
}

void _ensureAchievements(AppState state) {
  for (final achievement in state.achievements) {
    achievement.def ??= achievementDefinitions
        .where((definition) => definition.id == achievement.id)
        .firstOrNull;
  }
  for (final definition in achievementDefinitions) {
    if (!state.achievements.any((item) => item.id == definition.id)) {
      state.achievements.add(Achievement(id: definition.id)..def = definition);
    }
  }
}

void _setAchievement(AppState state, String id, bool unlocked) {
  _ensureAchievements(state);
  final achievement = state.achievements
      .where((item) => item.id == id)
      .firstOrNull;
  if (achievement == null) return;
  achievement.unlockedAt = unlocked ? DateTime.now() : null;
}

@visibleForTesting
DebugScenarioDef? debugScenarioById(String id) {
  for (final scenario in debugScenarios) {
    if (scenario.id == id) return scenario;
  }
  return null;
}
