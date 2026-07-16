part of '../main_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE BAR
// Direct AppStateProvider consumer for immediate XP bar updates.
// Avatar, name, and level badge all open the Profile dialog on tap.
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileBar extends StatelessWidget {
  final bool isDark;
  final bool mobile;
  final AppState? state;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onRewardsTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onAppIconTap;
  final VoidCallback? onProfileTap;
  final GlobalKey? rewardsKey;
  final GlobalKey? statsKey;

  const ProfileBar({
    super.key,
    required this.isDark,
    this.mobile = false,
    this.state,
    this.onToggleTheme,
    this.onRewardsTap,
    this.onStatsTap,
    this.onAppIconTap,
    this.onProfileTap,
    this.rewardsKey,
    this.statsKey,
  });

  void _openProfile(BuildContext context) {
    final callback = onProfileTap;
    if (callback != null) {
      callback();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AppStateProvider(
        state: AppStateProvider.of(context),
        child: const ProfileDialog(),
      ),
    );
  }

  void _openHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => FAQDialog(isDark: isDark),
    );
  }

  void _openMobileMenu(BuildContext context, AppState state) {
    final outerContext = context;
    final rewardsTap = onRewardsTap;
    final statsTap = onStatsTap;
    final toggleTheme = onToggleTheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.pop(sheetContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (outerContext.mounted) action();
          });
        }

        return SafeArea(
          top: false,
          child: Container(
            key: const ValueKey('mobile-header-menu-sheet'),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            decoration: BoxDecoration(
              color: MobileJournalTokens.surface(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subtext(isDark).withAlpha(80),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAppIconTap,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A9EFF).withAlpha(24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Color(0xFF4A9EFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RPG To-Do List',
                                style: TextStyle(
                                  color: textColor(isDark),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                kAppVersionLabel,
                                style: TextStyle(
                                  color: subtext(isDark),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-profile'),
                    icon: Icons.person_outline_rounded,
                    title: 'Профиль',
                    subtitle: 'Имя, аватар и настройки обучения',
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: () => closeThen(() => _openProfile(outerContext)),
                  ),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-rewards'),
                    icon: Icons.redeem_rounded,
                    title: 'Трофеи и эффекты',
                    subtitle: state.unopenedRewardChests.isEmpty
                        ? 'Награды после заметных действий'
                        : 'Новых сундуков: ${state.unopenedRewardChests.length}',
                    color: const Color(0xFFFFCC00),
                    badge: state.unopenedRewardChests.length,
                    isDark: isDark,
                    onTap: rewardsTap == null
                        ? null
                        : () => closeThen(rewardsTap),
                  ),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-stats'),
                    icon: Icons.query_stats_rounded,
                    title: 'Статистика',
                    subtitle: 'История роста и обзор недели',
                    color: const Color(0xFF34C759),
                    isDark: isDark,
                    onTap: statsTap == null ? null : () => closeThen(statsTap),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Интерфейс',
                    style: TextStyle(
                      color: subtext(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-sound'),
                    icon: state.sfxEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    title: state.sfxEnabled ? 'Звук включён' : 'Звук выключен',
                    subtitle: 'Звуки интерфейса и наград',
                    color: state.sfxEnabled
                        ? const Color(0xFF4A9EFF)
                        : const Color(0xFFFF9500),
                    isDark: isDark,
                    onTap: () => closeThen(state.toggleSfxEnabled),
                  ),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-reduced-motion'),
                    icon: Icons.motion_photos_off_rounded,
                    title: 'Снизить анимации',
                    subtitle: 'Уменьшает движение и отключает лишние переходы.',
                    color: const Color(0xFF5E5CE6),
                    isDark: isDark,
                    toggled: state.reducedMotion,
                    onTap: () => closeThen(state.toggleReducedMotion),
                  ),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-theme'),
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    title: isDark ? 'Светлая тема' : 'Тёмная тема',
                    subtitle: 'Переключить оформление приложения',
                    color: const Color(0xFF8E8E93),
                    isDark: isDark,
                    onTap: toggleTheme == null
                        ? null
                        : () => closeThen(toggleTheme),
                  ),
                  _MobileMenuTile(
                    key: const ValueKey('mobile-menu-help'),
                    icon: Icons.help_outline_rounded,
                    title: 'Помощь',
                    subtitle: 'Короткий гид по приложению',
                    color: const Color(0xFFAF52DE),
                    isDark: isDark,
                    onTap: () => closeThen(() => _openHelp(outerContext)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = state ?? AppStateProvider.of(context);
    final profile = appState.profile;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    if (mobile) {
      final metrics = MobileResponsiveMetrics.of(context);
      final typography = MobileJournalTokens.textTheme(context, isDark);
      final rewardsCount = appState.unopenedRewardChests.length;
      return SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: _MobileJournalTokens.surfaceColor(isDark),
            border: Border(
              bottom: BorderSide(
                color: _MobileJournalTokens.outline(isDark).withAlpha(130),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            metrics.pagePadding,
            12,
            math.max(10, metrics.pagePadding - 4),
            12,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Открыть профиль ${profile.name}',
                child: GestureDetector(
                  onTap: () => _openProfile(context),
                  child: _ProfileAvatar(profile: profile, size: 52),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label:
                      '${profile.name}, уровень ${profile.level}, ${profile.xp} из ${profile.xpNeeded} XP',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openProfile(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.titleLarge,
                              ),
                            ),
                            const SizedBox(width: 7),
                            LvlBadge(
                              level: profile.level,
                              color: _MobileJournalTokens.violet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: XPBar(
                                progress: profile.progress,
                                color: _MobileJournalTokens.violet,
                                height: 7,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${profile.xp}/${profile.xpNeeded}',
                              style: TextStyle(
                                color: _MobileJournalTokens.muted(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              KeyedSubtree(
                key: rewardsKey,
                child: KeyedSubtree(
                  key: statsKey,
                  child: Semantics(
                    button: true,
                    label: rewardsCount > 0
                        ? 'Открыть меню, новых сундуков: $rewardsCount'
                        : 'Открыть меню',
                    child: IconButton(
                      key: const ValueKey('mobile-header-menu'),
                      tooltip: 'Меню',
                      onPressed: () => _openMobileMenu(context, appState),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                        backgroundColor: isDark
                            ? _MobileJournalTokens.raisedDark
                            : _MobileJournalTokens.raised(false),
                      ),
                      icon: Badge(
                        isLabelVisible: rewardsCount > 0,
                        label: Text('$rewardsCount'),
                        backgroundColor: const Color(0xFFFF9500),
                        child: const Icon(Icons.more_horiz_rounded),
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

    return Container(
      color: sfc,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Row(
        children: [
          // Avatar — clickable → profile
          HoverScale(
            child: Tooltip(
              message: 'Открыть профиль',
              child: GestureDetector(
                onTap: () => _openProfile(context),
                child: _ProfileAvatar(profile: profile, size: 38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Name — clickable → profile
                    Flexible(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Tooltip(
                          message: 'Открыть профиль',
                          child: GestureDetector(
                            onTap: () => _openProfile(context),
                            child: Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: txt,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Level badge — clickable → profile
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: 'Открыть профиль',
                        child: GestureDetector(
                          onTap: () => _openProfile(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LvlBadge(
                                level: profile.level,
                                color: const Color(0xFF4A9EFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: XPBar(
                        progress: profile.progress,
                        color: const Color(0xFF4A9EFF),
                        height: 7,
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

class _ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  final double size;

  const _ProfileAvatar({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    final avatarDecodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: profile.avatarBytes == null
            ? const LinearGradient(
                colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: profile.avatarBytes != null
            ? DecorationImage(
                image: ResizeImage.resizeIfNeeded(
                  avatarDecodeSize,
                  avatarDecodeSize,
                  MemoryImage(profile.avatarBytes!),
                ),
                fit: BoxFit.cover,
              )
            : null,
        shape: BoxShape.circle,
      ),
      child: profile.avatarBytes == null
          ? Center(
              child: Text(
                profile.initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.42,
                ),
              ),
            )
          : null,
    );
  }
}

class _MobileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final int badge;
  final bool? toggled;
  final VoidCallback? onTap;

  const _MobileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    this.badge = 0,
    this.toggled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      toggled: toggled,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 24 : 16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: MobileJournalTokens.text(isDark),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MobileJournalTokens.muted(isDark),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (toggled != null)
                Icon(
                  toggled! ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  color: toggled! ? color : subtext(isDark),
                  size: 34,
                )
              else if (badge > 0)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 34 : 22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: subtext(isDark)),
            ],
          ),
        ),
      ),
    );
  }
}
