part of '../main_page.dart';

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
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Row(
        children: [
          // Avatar — clickable → profile
          HoverScale(
            child: Tooltip(
              message: 'Открыть профиль',
              child: GestureDetector(
                onTap: () => _openProfile(context),
                child: Container(
                  width: 38,
                  height: 38,
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
                            image: MemoryImage(profile.avatarBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: profile.avatarBytes == null
                      ? Center(
                          child: Text(
                            profile.initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : null,
                ),
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
