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
  bool _effectsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tokens = widget.tokens;
    final buffs = state.activeBuffs;
    final chests = state.unopenedRewardChests;
    return _DesktopPageScaffold(
      tokens: tokens,
      icon: Icons.emoji_events_outlined,
      color: tokens.rewardGold,
      title: 'Трофеи после действий',
      subtitle: 'Награды появляются после заметных действий и рубежей пути.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DesktopSectionCard(
            tokens: tokens,
            child: Column(
              children: [
                InkWell(
                  key: const ValueKey('desktop-rewards-effects'),
                  onTap: () =>
                      setState(() => _effectsExpanded = !_effectsExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, color: tokens.successGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Эффекты',
                            style: TextStyle(
                              color: tokens.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _DesktopCountPill(
                          value: buffs.length,
                          color: tokens.successGreen,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _effectsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: tokens.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
                MotionExpandable(
                  expanded: _effectsExpanded,
                  expandedChild: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                  collapsedChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'НОВЫЕ СУНДУКИ',
            style: TextStyle(
              color: tokens.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          if (chests.isEmpty)
            _DesktopSectionCard(
              tokens: tokens,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _DesktopEmptyMessage(
                  tokens: tokens,
                  icon: Icons.inventory_2_outlined,
                  title: 'Пока нет сундуков',
                  subtitle:
                      'Закрой сильный день, удержи серию или пройди событие сопротивления.',
                ),
              ),
            )
          else
            ...chests.map(
              (chest) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DesktopSectionCard(
                  tokens: tokens,
                  child: ListTile(
                    leading: Icon(
                      Icons.redeem_rounded,
                      color: tokens.rewardGold,
                    ),
                    title: Text(
                      chest.title,
                      style: TextStyle(
                        color: tokens.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      chest.description,
                      style: TextStyle(color: tokens.mutedText),
                    ),
                    trailing: FilledButton(
                      onPressed: () => state.openRewardChest(chest.id),
                      child: const Text('Открыть'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
      subtitle: 'Профиль, звук и комфорт интерфейса.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _DesktopSectionCard(
          tokens: tokens,
          child: Column(
            children: [
              _DesktopSettingsTile(
                tokens: tokens,
                icon: Icons.person_outline,
                title: 'Профиль персонажа',
                subtitle: 'Имя, аватар и обучение',
                onTap: onOpenProfile,
              ),
              _DesktopSettingsSwitch(
                tokens: tokens,
                icon: Icons.volume_up_outlined,
                title: 'Звуки интерфейса',
                value: state.sfxEnabled,
                onChanged: (_) => state.toggleSfxEnabled(),
              ),
              _DesktopSettingsSwitch(
                tokens: tokens,
                icon: Icons.lightbulb_outline,
                title: 'Подсказки',
                value: state.tooltipsEnabled,
                onChanged: (_) => state.toggleTooltipsEnabled(),
              ),
              _DesktopSettingsSwitch(
                tokens: tokens,
                icon: Icons.motion_photos_off_outlined,
                title: 'Сокращать анимации',
                value: state.reducedMotion,
                onChanged: (_) => state.toggleReducedMotion(),
              ),
              _DesktopSettingsSwitch(
                tokens: tokens,
                icon: Icons.dark_mode_outlined,
                title: 'Тёмная тема',
                value: state.isDark,
                onChanged: (_) => state.toggleTheme(),
              ),
            ],
          ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Column(
      children: [
        Icon(icon, color: tokens.mutedText, size: 36),
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

class _DesktopSettingsSwitch extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DesktopSettingsSwitch({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: tokens.mutedText),
    title: Text(title, style: TextStyle(color: tokens.text)),
    value: value,
    onChanged: onChanged,
  );
}
