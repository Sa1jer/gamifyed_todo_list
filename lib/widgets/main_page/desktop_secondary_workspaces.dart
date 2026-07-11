part of '../main_page.dart';

class _DesktopPageScaffold extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  const _DesktopPageScaffold({
    required this.tokens,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tokens.mainSurface,
      child: CustomScrollView(
        key: ValueKey('desktop-page-$title'),
        primary: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: tokens.text,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: tokens.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );
  }
}

class _DesktopRewardsWorkspace extends StatefulWidget {
  final AppState state;
  final DesktopJournalTokens tokens;

  const _DesktopRewardsWorkspace({
    super.key,
    required this.state,
    required this.tokens,
  });

  @override
  State<_DesktopRewardsWorkspace> createState() =>
      _DesktopRewardsWorkspaceState();
}

class _DesktopRewardsWorkspaceState extends State<_DesktopRewardsWorkspace> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tokens = widget.tokens;
    final buffs = state.activeBuffs;
    final chests = state.unopenedRewardChests;
    final progress = <_DesktopTrophyProgress>[
      _DesktopTrophyProgress(
        icon: Icons.local_fire_department_outlined,
        color: tokens.streakAmber,
        title: 'Серия 7 дней',
        condition: 'Повторяющиеся квесты подряд',
        current: math.min(state.bestStreak, 7),
        target: 7,
      ),
      _DesktopTrophyProgress(
        icon: Icons.trending_up_rounded,
        color: tokens.rewardGold,
        title: 'Первый рубеж',
        condition: 'Достигнуть 5 уровня персонажа',
        current: math.min(state.profile.level, 5),
        target: 5,
      ),
      _DesktopTrophyProgress(
        icon: Icons.bolt_rounded,
        color: tokens.danger,
        title: 'Сильный день',
        condition: 'Закрыть 5 квестов за один день',
        current: math.min(state.todayStats?.tasksCompleted ?? 0, 5),
        target: 5,
      ),
    ];
    return _DesktopPageScaffold(
      tokens: tokens,
      icon: Icons.emoji_events_outlined,
      color: tokens.rewardGold,
      title: 'Трофеи после действий',
      subtitle: 'Награды появляются после заметных действий и рубежей пути.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'В ПРОЦЕССЕ',
            style: TextStyle(
              color: tokens.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              key: const ValueKey('desktop-trophies-in-progress'),
              crossAxisCount: constraints.maxWidth >= 900 ? 3 : 1,
              childAspectRatio: constraints.maxWidth >= 900 ? 2.25 : 4.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: progress
                  .map(
                    (item) => _DesktopTrophyProgressCard(
                      progress: item,
                      tokens: tokens,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 22),
          _DesktopSectionCard(
            tokens: tokens,
            child: _DesktopRewardCollection(
              key: const ValueKey('desktop-rewards-effects'),
              tokens: tokens,
              icon: Icons.bolt_rounded,
              color: tokens.successGreen,
              title: 'Эффекты',
              count: buffs.length,
              child: buffs.isEmpty
                  ? _DesktopEmptyMessage(
                      tokens: tokens,
                      icon: Icons.bolt_outlined,
                      title: 'Нет эффектов',
                      subtitle:
                          'Открой сундук, и здесь появится временное усиление.',
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: buffs
                          .map(
                            (buff) => Chip(
                              avatar: Icon(
                                Icons.auto_awesome,
                                color: tokens.successGreen,
                                size: 17,
                              ),
                              label: Text(buff.title),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          _DesktopSectionCard(
            tokens: tokens,
            child: _DesktopRewardCollection(
              key: const ValueKey('desktop-rewards-chests'),
              tokens: tokens,
              icon: Icons.inventory_2_outlined,
              color: tokens.rewardGold,
              title: 'Новые сундуки',
              count: chests.length,
              child: chests.isEmpty
                  ? _DesktopEmptyMessage(
                      tokens: tokens,
                      icon: Icons.inventory_2_outlined,
                      title: 'Пока нет сундуков',
                      subtitle:
                          'Закрой сильный день, удержи серию или пройди событие сопротивления.',
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 760;
                        final itemWidth = twoColumns
                            ? (constraints.maxWidth - 10) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: chests
                              .map(
                                (chest) => SizedBox(
                                  width: itemWidth,
                                  child: _DesktopRewardChestCard(
                                    chest: chest,
                                    tokens: tokens,
                                    onOpen: () =>
                                        state.openRewardChest(chest.id),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'КАК ПОЛУЧИТЬ ТРОФЕИ',
            style: TextStyle(
              color: tokens.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              key: const ValueKey('desktop-trophies-how-to'),
              crossAxisCount: constraints.maxWidth >= 720 ? 3 : 1,
              childAspectRatio: constraints.maxWidth >= 720 ? 2.35 : 4.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DesktopTrophyHowToCard(
                  tokens: tokens,
                  icon: Icons.bolt_rounded,
                  color: tokens.streakAmber,
                  title: 'Сильный день',
                  description:
                      'Закрой 5 квестов за день, чтобы получить сундук дисциплины.',
                ),
                _DesktopTrophyHowToCard(
                  tokens: tokens,
                  icon: Icons.local_fire_department_outlined,
                  color: tokens.rewardGold,
                  title: 'Серия дней',
                  description:
                      'Удерживай повторяющийся квест 7 или 30 дней для редких сундуков.',
                ),
                _DesktopTrophyHowToCard(
                  tokens: tokens,
                  icon: Icons.shield_outlined,
                  color: tokens.danger,
                  title: 'Победа над сопротивлением',
                  description:
                      'Заверши активное событие сопротивления, чтобы открыть трофей.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTrophyProgress {
  final IconData icon;
  final Color color;
  final String title;
  final String condition;
  final int current;
  final int target;

  const _DesktopTrophyProgress({
    required this.icon,
    required this.color,
    required this.title,
    required this.condition,
    required this.current,
    required this.target,
  });

  double get value => target <= 0 ? 0 : (current / target).clamp(0, 1);
}

class _DesktopTrophyProgressCard extends StatelessWidget {
  final _DesktopTrophyProgress progress;
  final DesktopJournalTokens tokens;

  const _DesktopTrophyProgressCard({
    required this.progress,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${progress.title}: ${progress.current} из ${progress.target}, ${(progress.value * 100).round()} процентов',
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: progress.color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: progress.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(progress.icon, color: progress.color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${(progress.value * 100).round()}%',
                style: TextStyle(
                  color: progress.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${progress.current}/${progress.target} · ${progress.condition}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.mutedText, fontSize: 10.5),
          ),
          const SizedBox(height: 9),
          _DesktopProgressBar(
            value: progress.value,
            color: progress.color,
            background: progress.color.withValues(alpha: 0.12),
            height: 6,
          ),
        ],
      ),
    ),
  );
}

class _DesktopTrophyHowToCard extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _DesktopTrophyHowToCard({
    required this.tokens,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tokens.cardSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.mutedText,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DesktopSettingsWorkspace extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final VoidCallback onOpenProfile;

  const _DesktopSettingsWorkspace({
    super.key,
    required this.state,
    required this.tokens,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return _DesktopPageScaffold(
      tokens: tokens,
      icon: Icons.settings_outlined,
      color: tokens.profilePurple,
      title: 'Настройки',
      subtitle:
          'Профиль, внешний вид, движение, звук и состояние локальных данных.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DesktopSettingsSection(
              tokens: tokens,
              title: 'Профиль',
              child: _DesktopSettingsTile(
                tokens: tokens,
                icon: Icons.person_outline,
                title: 'Профиль персонажа',
                subtitle:
                    '${state.profile.name} · уровень ${state.profile.level} · аватар и обучение',
                onTap: onOpenProfile,
              ),
            ),
            const SizedBox(height: 18),
            _DesktopSettingsSection(
              tokens: tokens,
              title: 'Внешний вид и движение',
              child: Column(
                children: [
                  _DesktopSettingsSwitch(
                    key: const ValueKey('desktop-settings-theme'),
                    tokens: tokens,
                    icon: Icons.dark_mode_outlined,
                    title: 'Тёмная тема',
                    subtitle: 'Переключается сразу и сохраняется на устройстве',
                    value: state.isDark,
                    onChanged: (_) => state.toggleTheme(),
                  ),
                  _DesktopSettingsSwitch(
                    key: const ValueKey('desktop-settings-motion'),
                    tokens: tokens,
                    icon: Icons.motion_photos_off_outlined,
                    title: 'Сокращать анимации',
                    subtitle: 'Убирает необязательные перемещения и переходы',
                    value: state.reducedMotion,
                    onChanged: (_) => state.toggleReducedMotion(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DesktopSettingsSection(
              tokens: tokens,
              title: 'Звук и помощь',
              child: Column(
                children: [
                  _DesktopSettingsSwitch(
                    key: const ValueKey('desktop-settings-sound'),
                    tokens: tokens,
                    icon: Icons.volume_up_outlined,
                    title: 'Звуки интерфейса',
                    subtitle: 'Отклик за действия, XP и награды',
                    value: state.sfxEnabled,
                    onChanged: (_) => state.toggleSfxEnabled(),
                  ),
                  _DesktopSettingsSwitch(
                    key: const ValueKey('desktop-settings-tooltips'),
                    tokens: tokens,
                    icon: Icons.lightbulb_outline,
                    title: 'Подсказки интерфейса',
                    subtitle: 'Пояснения к иконкам и сложным действиям',
                    value: state.tooltipsEnabled,
                    onChanged: (_) => state.toggleTooltipsEnabled(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DesktopSettingsSection(
              tokens: tokens,
              title: 'Данные на устройстве',
              child: _DesktopSettingsStatus(
                tokens: tokens,
                hasError: state.hasPersistenceError,
                dirty: state.persistenceStatus.isDirty,
              ),
            ),
            const SizedBox(height: 18),
            _DesktopSettingsSection(
              tokens: tokens,
              title: 'О приложении',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: tokens.mutedText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'RPG To-Do List',
                        style: TextStyle(
                          color: tokens.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      kAppVersionLabel,
                      style: TextStyle(
                        color: tokens.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSectionCard extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final Widget child;

  const _DesktopSectionCard({required this.tokens, required this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: tokens.cardSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: tokens.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

/// Shared content-led anatomy for effects and unopened chests.
/// Both collections grow only with their content instead of reserving a panel.
class _DesktopRewardCollection extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final Widget child;

  const _DesktopRewardCollection({
    super.key,
    required this.tokens,
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : DesktopJournalTokens.standardMotion,
    curve: DesktopJournalTokens.motionCurve,
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: context.appTextTheme.titleMedium?.copyWith(
                    color: tokens.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DesktopCountPill(value: count, color: color, tokens: tokens),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _DesktopEmptyMessage extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;

  const _DesktopEmptyMessage({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 142),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: tokens.mutedText, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: tokens.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.mutedText, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DesktopRewardChestCard extends StatelessWidget {
  final RewardChest chest;
  final DesktopJournalTokens tokens;
  final VoidCallback onOpen;

  const _DesktopRewardChestCard({
    required this.chest,
    required this.tokens,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => _DesktopSectionCard(
    tokens: tokens,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tokens.rewardGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.redeem_rounded,
              color: tokens.rewardGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chest.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.mutedText, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              foregroundColor: tokens.rewardGold,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Открыть'),
          ),
        ],
      ),
    ),
  );
}

class _DesktopCountPill extends StatelessWidget {
  final int value;
  final Color color;
  final DesktopJournalTokens tokens;

  const _DesktopCountPill({
    required this.value,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$value',
      style: TextStyle(color: color, fontWeight: FontWeight.w900),
    ),
  );
}

class _DesktopSettingsTile extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DesktopSettingsTile({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 68,
    leading: Icon(icon, color: tokens.profilePurple),
    title: Text(title, style: TextStyle(color: tokens.text)),
    subtitle: Text(subtitle, style: TextStyle(color: tokens.mutedText)),
    trailing: Icon(Icons.chevron_right, color: tokens.mutedText),
    onTap: onTap,
  );
}

class _DesktopSettingsSection extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final String title;
  final Widget child;

  const _DesktopSettingsSection({
    required this.tokens,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: tokens.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
      _DesktopSectionCard(tokens: tokens, child: child),
    ],
  );
}

class _DesktopSettingsStatus extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final bool hasError;
  final bool dirty;

  const _DesktopSettingsStatus({
    required this.tokens,
    required this.hasError,
    required this.dirty,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? tokens.danger
        : dirty
        ? tokens.streakAmber
        : tokens.successGreen;
    final title = hasError
        ? 'Требуется повтор сохранения'
        : dirty
        ? 'Изменения ещё сохраняются'
        : 'Данные сохранены локально';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasError ? Icons.warning_amber_rounded : Icons.save_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Хранилище работает на этом устройстве; cloud sync не включён.',
                  style: TextStyle(color: tokens.mutedText, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSettingsSwitch extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DesktopSettingsSwitch({
    super.key,
    required this.tokens,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: tokens.mutedText),
    title: Text(title, style: TextStyle(color: tokens.text)),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, style: TextStyle(color: tokens.mutedText)),
    value: value,
    onChanged: onChanged,
  );
}
