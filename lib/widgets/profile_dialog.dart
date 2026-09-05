// To-Do List RPG — Profile Dialog
// Requires: file_picker: ^8.1.0 in pubspec.yaml
// macOS entitlements: com.apple.security.files.user-selected.read-only = true

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import '../app_state.dart';
import '../tutorial/guided_tour_session.dart';
import '../utils.dart';
import 'character_timeline_dialog.dart';
import 'mobile_secondary_page.dart';
import 'shared.dart';
import 'tutorial/tutorial_training_center.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileDialog extends StatefulWidget {
  final bool fullScreen;
  final VoidCallback? onToggleTheme;
  final GuidedTourSessionSnapshot? tutorialSession;
  final ValueChanged<TutorialTrainingSelection>? onTutorialSelection;
  final Key? tutorialTrainingKey;
  final Widget? tutorialOverlay;

  const ProfileDialog({
    super.key,
    this.fullScreen = false,
    this.onToggleTheme,
    this.tutorialSession,
    this.onTutorialSelection,
    this.tutorialTrainingKey,
    this.tutorialOverlay,
  });
  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  bool _editingName = false;
  bool _didInitControllers = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
  }

  Future<void> _openTrainingCenter(BuildContext context, AppState state) async {
    final selection = await showTutorialTrainingCenter(
      context: context,
      progress: state.tutorialProgress,
      session: widget.tutorialSession,
    );
    final onSelected = widget.onTutorialSelection;
    if (selection == null || onSelected == null || !context.mounted) return;
    await Navigator.of(context).maybePop();
    onSelected(selection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitControllers) return;

    final profile = AppStateProvider.of(context).profile;
    _nameCtrl.text = profile.name;
    _ageCtrl.text = profile.age?.toString() ?? '';
    _didInitControllers = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<Uint8List?> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final bytes = result?.files.firstOrNull?.bytes;
      if (bytes == null) return null;
      return hasSupportedImageMagicBytes(bytes) ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final p = s.profile;
    final isDark = s.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    if (widget.fullScreen) {
      return _withTutorialOverlay(
        _buildMobileProfilePage(context, s, p, isDark, bg, txt, sub, bdr),
      );
    }

    // Ширина окна берётся от экрана, а не задаётся жёстко: две колонки на
    // узком десктопе сжались бы в кашу. Порог — 900 px содержимого плюс
    // 120 px insetPadding.
    final available = MediaQuery.sizeOf(context);
    final wide = available.width - 120 >= 900;

    // «Кто ты» — то, что про пользователя и его путь.
    final identityColumn = <Widget>[
      _buildPersonalInfo(context, s, p, isDark, txt, sub, bdr),
      const SizedBox(height: 24),
      SubLbl('Прогресс', sub),
      const SizedBox(height: 10),
      _buildTotalXP(context, p, txt, sub),
      const SizedBox(height: 4),
      Text(
        'Изучаю ${s.activeSkillCount} ${_skillWord(s.activeSkillCount)}',
        style: TextStyle(color: sub, fontSize: 13),
      ),
      const SizedBox(height: 10),
      _ProfileTimelineButton(
        state: s,
        isDark: isDark,
        txt: txt,
        sub: sub,
        fullScreen: widget.fullScreen,
      ),
      const SizedBox(height: 24),
      _buildSkillsSection(context, s, isDark, txt, sub),
    ];

    // «Что можно изменить» — настройки устройства и данные.
    final settingsColumn = <Widget>[
      _buildInterfaceSettings(s, isDark, txt, sub, bdr),
      const SizedBox(height: 24),
      _buildDataTransfer(context, s, isDark, txt, sub, bdr),
    ];

    // Разделители-линии убраны: у каждой секции уже есть собственная
    // подпись, и шесть одинаковых линий только мешали увидеть границы тем.
    final body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: ListView(
                  key: const ValueKey('desktop-profile-body-scroll'),
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
                  children: identityColumn,
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: bdr),
              Expanded(
                flex: 4,
                child: ListView(
                  key: const ValueKey('desktop-profile-settings-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
                  children: settingsColumn,
                ),
              ),
            ],
          )
        : ListView(
            key: const ValueKey('desktop-profile-body-scroll'),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              ...identityColumn,
              const SizedBox(height: 24),
              ...settingsColumn,
            ],
          );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullScreen ? 0 : 20),
      child: Container(
        width: widget.fullScreen
            ? double.infinity
            : wide
            ? 900
            : 460,
        constraints: widget.fullScreen
            ? const BoxConstraints()
            // На широкой раскладке окно занимает всю доступную высоту: то,
            // что не занято, всё равно осталось бы пустым полем вокруг
            // диалога, а каждый лишний пиксель здесь снимает прокрутку.
            : BoxConstraints(
                maxHeight: wide
                    ? (available.height - 80).clamp(560.0, 900.0)
                    : 680,
              ),
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDesktopProfileHero(
              context,
              s,
              p,
              isDark,
              txt,
              sub,
              bdr,
              wide: wide,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );

    return _withTutorialOverlay(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: content,
      ),
    );
  }

  Widget _withTutorialOverlay(Widget child) {
    final overlay = widget.tutorialOverlay;
    if (overlay == null) return child;
    return Stack(fit: StackFit.expand, children: [child, overlay]);
  }

  Widget _buildMobileProfilePage(
    BuildContext context,
    AppState state,
    UserProfile profile,
    bool isDark,
    Color background,
    Color text,
    Color secondary,
    Color border,
  ) {
    return MobileSecondaryPage(
      routeName: 'Профиль',
      backgroundColor: background,
      header: const MobileSecondaryHeader(
        title: 'Профиль',
        subtitle: 'Персонаж, прогресс и настройки',
        icon: Icons.person_rounded,
        accentColor: Color(0xFF7562FF),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildMobileProfileHero(
              context,
              state,
              profile,
              isDark,
              text,
              secondary,
              border,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              key: const ValueKey('mobile-profile-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SubLbl('Прогресс', secondary),
                const SizedBox(height: 10),
                _buildTotalXP(context, profile, text, secondary),
                const SizedBox(height: 5),
                Text(
                  'Изучаю ${state.activeSkillCount} ${_skillWord(state.activeSkillCount)}',
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _ProfileTimelineButton(
                  state: state,
                  isDark: isDark,
                  txt: text,
                  sub: secondary,
                  fullScreen: true,
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: border),
                const SizedBox(height: 16),
                _buildPersonalInfo(
                  context,
                  state,
                  profile,
                  isDark,
                  text,
                  secondary,
                  border,
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: border),
                const SizedBox(height: 16),
                _buildInterfaceSettings(state, isDark, text, secondary, border),
                const SizedBox(height: 18),
                Container(height: 1, color: border),
                const SizedBox(height: 16),
                _buildDataTransfer(
                  context,
                  state,
                  isDark,
                  text,
                  secondary,
                  border,
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: border),
                const SizedBox(height: 16),
                _buildSkillsSection(context, state, isDark, text, secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProfileHero(
    BuildContext context,
    AppState state,
    UserProfile profile,
    bool isDark,
    Color text,
    Color secondary,
    Color border, {
    required bool wide,
  }) {
    return DecoratedBox(
      key: const ValueKey('desktop-profile-fixed-hero'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171925) : const Color(0xFFF7F8FC),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomLeft,
            children: [
              Column(
                children: [
                  _buildBannerSection(context, state, profile),
                  const SizedBox(height: 42),
                ],
              ),
              Positioned(
                left: 24,
                bottom: 0,
                child: _buildAvatar(context, state, profile, isDark),
              ),
            ],
          ),
          Padding(
            padding: wide
                ? const EdgeInsets.fromLTRB(24, 6, 24, 10)
                : const EdgeInsets.fromLTRB(24, 10, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // На широкой раскладке имя, уровень и полоса опыта занимают
                // две строки вместо четырёх блоков: шапка забирала половину
                // окна именно здесь.
                if (wide)
                  Row(
                    children: [
                      Expanded(
                        child: _buildNameRow(
                          context,
                          state,
                          profile,
                          text,
                          secondary,
                          offsetForAvatar: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      LvlBadge(
                        level: profile.level,
                        color: const Color(0xFF4A9EFF),
                      ),
                    ],
                  )
                else ...[
                  _buildNameRow(
                    context,
                    state,
                    profile,
                    text,
                    secondary,
                    offsetForAvatar: false,
                  ),
                  const SizedBox(height: 7),
                  LvlBadge(
                    level: profile.level,
                    color: const Color(0xFF4A9EFF),
                  ),
                ],
                SizedBox(height: wide ? 6 : 12),
                _buildXPSection(context, profile, secondary, compact: wide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileHero(
    BuildContext context,
    AppState state,
    UserProfile profile,
    bool isDark,
    Color text,
    Color secondary,
    Color border,
  ) {
    return Container(
      key: const ValueKey('mobile-profile-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171925) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Column(
                children: [
                  _buildBannerArtwork(context, state, profile, height: 132),
                  const SizedBox(height: 42),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: _buildAvatar(context, state, profile, isDark),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNameRow(
                  context,
                  state,
                  profile,
                  text,
                  secondary,
                  offsetForAvatar: false,
                ),
                const SizedBox(height: 8),
                LvlBadge(level: profile.level, color: const Color(0xFF4A9EFF)),
                const SizedBox(height: 14),
                _buildXPSection(context, profile, secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner + Avatar ────────────────────────────────────────────────────────

  Widget _buildBannerSection(BuildContext context, AppState s, UserProfile p) {
    return SizedBox(
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBannerArtwork(context, s, p, height: 160),
          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: Tooltip(
              message: 'Закрыть профиль',
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerArtwork(
    BuildContext context,
    AppState state,
    UserProfile profile, {
    required double height,
  }) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Tooltip(
      message: 'Изменить баннер профиля',
      child: GestureDetector(
        onTap: () async {
          final bytes = await _pickImage();
          if (bytes != null && context.mounted) {
            state.updateProfileBanner(bytes);
          }
        },
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: height,
              child: profile.bannerBytes != null
                  ? Image.memory(
                      profile.bannerBytes!,
                      fit: BoxFit.cover,
                      cacheHeight: (height * pixelRatio).round(),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withAlpha(40),
                child: Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white.withAlpha(120),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    AppState s,
    UserProfile p,
    bool isDark,
  ) {
    final avatarDecodeSize = (80 * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Tooltip(
      message: 'Изменить аватар',
      child: GestureDetector(
        onTap: () async {
          final bytes = await _pickImage();
          if (bytes != null && context.mounted) {
            s.updateProfileAvatar(bytes);
          }
        },
        child: Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: surface(isDark), width: 3),
                gradient: p.avatarBytes == null
                    ? const LinearGradient(
                        colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: p.avatarBytes != null
                    ? DecorationImage(
                        image: ResizeImage.resizeIfNeeded(
                          avatarDecodeSize,
                          avatarDecodeSize,
                          MemoryImage(p.avatarBytes!),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: p.avatarBytes == null
                  ? Center(
                      child: Text(
                        p.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                        ),
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A9EFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Name row ──────────────────────────────────────────────────────────────

  Widget _buildNameRow(
    BuildContext context,
    AppState s,
    UserProfile p,
    Color txt,
    Color sub, {
    bool offsetForAvatar = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: offsetForAvatar ? 50 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_editingName)
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: txt,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (v) {
                  s.updateProfileName(v);
                  setState(() => _editingName = false);
                },
              ),
            )
          else
            Expanded(
              child: Tooltip(
                message: 'Редактировать имя профиля',
                child: GestureDetector(
                  onTap: () => setState(() => _editingName = true),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: txt,
                    ),
                  ),
                ),
              ),
            ),
          if (_editingName)
            IconButton(
              tooltip: 'Сохранить имя',
              icon: const Icon(
                Icons.check_circle,
                color: Color(0xFF4A9EFF),
                size: 22,
              ),
              onPressed: () {
                s.updateProfileName(_nameCtrl.text);
                setState(() => _editingName = false);
              },
            )
          else
            Tooltip(
              message: 'Редактировать имя профиля',
              child: GestureDetector(
                onTap: () => setState(() => _editingName = true),
                child: Icon(Icons.edit_outlined, color: sub, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── XP section ────────────────────────────────────────────────────────────

  Widget _buildXPSection(
    BuildContext context,
    UserProfile p,
    Color sub, {
    bool compact = false,
  }) {
    // Подпись «До уровня N» повторяла то же самое третьим числом подряд.
    // В компактной шапке остаются уровень и полоса с остатком.
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: XPBar(
              progress: p.progress,
              color: const Color(0xFF4A9EFF),
              height: 8,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${p.xp} / ${p.xpNeeded}',
            style: TextStyle(color: sub, fontSize: 12),
          ),
        ],
      );
    }
    final stacked =
        widget.fullScreen && MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stacked) ...[
          Row(
            children: [
              Expanded(
                child: Text('Опыт', style: TextStyle(color: sub, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.xp} / ${p.xpNeeded}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: p.progress,
            color: const Color(0xFF4A9EFF),
            height: 8,
          ),
        ] else
          Row(
            children: [
              Text('Опыт', style: TextStyle(color: sub, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: XPBar(
                  progress: p.progress,
                  color: const Color(0xFF4A9EFF),
                  height: 8,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${p.xp} / ${p.xpNeeded}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'До уровня ${p.level + 1}: ${p.xpNeeded - p.xp} XP.',
          style: TextStyle(color: sub, fontSize: 12, height: 1.25),
        ),
      ],
    );
  }

  Widget _buildTotalXP(
    BuildContext context,
    UserProfile p,
    Color txt,
    Color sub,
  ) {
    final stacked =
        widget.fullScreen && MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Всего опыта', style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            '${p.totalXpEarned}',
            style: TextStyle(
              color: txt,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Text('Всего опыта', style: TextStyle(color: sub, fontSize: 13)),
        const Spacer(),
        Text(
          '${p.totalXpEarned}',
          style: TextStyle(
            color: txt,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Personal info ─────────────────────────────────────────────────────────

  Widget _buildPersonalInfo(
    BuildContext context,
    AppState s,
    UserProfile p,
    bool isDark,
    Color txt,
    Color sub,
    Color bdr,
  ) {
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final ageField = _buildAgeField(s, txt, sub, bdr, fBg);
    final genderField = _buildGenderField(
      context,
      s,
      p,
      isDark,
      txt,
      sub,
      bdr,
      fBg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubLbl('Личные данные', sub),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stacked = constraints.maxWidth < 360 || textScale >= 1.5;
            if (stacked) {
              return Column(
                children: [ageField, const SizedBox(height: 10), genderField],
              );
            }
            return Row(
              children: [
                Expanded(child: ageField),
                const SizedBox(width: 8),
                Expanded(child: genderField),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgeField(
    AppState state,
    Color text,
    Color secondary,
    Color border,
    Color background,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF8E8E93)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Возраст',
                hintStyle: TextStyle(color: secondary, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                state.updateProfileAge(int.tryParse(value.trim()));
              },
              onSubmitted: (value) {
                state.updateProfileAge(int.tryParse(value.trim()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField(
    BuildContext context,
    AppState state,
    UserProfile profile,
    bool isDark,
    Color text,
    Color secondary,
    Color border,
    Color background,
  ) {
    final label = profile.gender != null ? genderLabel[profile.gender]! : 'Пол';
    return Semantics(
      button: true,
      label: 'Пол: $label',
      child: Tooltip(
        message: 'Выбрать пол',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              _showGenderPicker(context, state, profile, isDark, secondary),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: profile.gender != null ? text : secondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: secondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGenderPicker(
    BuildContext context,
    AppState s,
    UserProfile p,
    bool isDark,
    Color sub,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => RadioGroup<Gender>(
        groupValue: p.gender,
        onChanged: (value) {
          s.updateProfileGender(value);
          Navigator.pop(sheetContext);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: sub.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ...Gender.values.map(
              (gender) => ListTile(
                title: Text(
                  genderLabel[gender]!,
                  style: TextStyle(color: textColor(isDark)),
                ),
                leading: Radio<Gender>(
                  value: gender,
                  activeColor: const Color(0xFF4A9EFF),
                ),
                onTap: () {
                  s.updateProfileGender(gender);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceSettings(
    AppState state,
    bool isDark,
    Color txt,
    Color sub,
    Color bdr,
  ) {
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);

    return KeyedSubtree(
      key: widget.tutorialTrainingKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubLbl('Интерфейс', sub),
          const SizedBox(height: 10),
          if (widget.onToggleTheme != null) ...[
            _ProfileSettingsToggle(
              background: fBg,
              border: bdr,
              text: txt,
              secondary: sub,
              icon: Icons.dark_mode_outlined,
              title: 'Тёмная тема',
              subtitle: 'Переключается сразу и сохраняется на устройстве.',
              value: state.isDark,
              onChanged: (_) => widget.onToggleTheme!(),
            ),
            const SizedBox(height: 8),
          ],
          _ProfileSettingsToggle(
            background: fBg,
            border: bdr,
            text: txt,
            secondary: sub,
            icon: Icons.volume_up_outlined,
            title: 'Звуки интерфейса',
            subtitle: 'Отклик на действия, XP и награды.',
            value: state.sfxEnabled,
            onChanged: (_) => state.toggleSfxEnabled(),
          ),
          const SizedBox(height: 8),
          _ProfileSettingsToggle(
            background: fBg,
            border: bdr,
            text: txt,
            secondary: sub,
            icon: Icons.motion_photos_off_outlined,
            title: 'Сокращать анимации',
            subtitle: 'Убирает необязательные перемещения и переходы.',
            value: state.reducedMotion,
            onChanged: (_) => state.toggleReducedMotion(),
          ),
          const SizedBox(height: 8),
          _ProfileSettingsToggle(
            background: fBg,
            border: bdr,
            text: txt,
            secondary: sub,
            icon: Icons.info_outline_rounded,
            title: 'Подсказки при наведении',
            subtitle: state.tooltipsEnabled
                ? 'Включены для кнопок и действий.'
                : 'Скрыты, интерфейс спокойнее.',
            value: state.tooltipsEnabled,
            onChanged: (_) => state.toggleTooltipsEnabled(),
          ),
          const SizedBox(height: 8),
          Material(
            color: fBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: bdr),
            ),
            child: InkWell(
              key: const ValueKey('profile-training-center-entry'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openTrainingCenter(context, state),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFF9500),
                      size: 17,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Обучение',
                            style: TextStyle(
                              color: txt,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Полный тур и отдельные темы всегда доступны здесь.',
                            style: TextStyle(color: sub, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: sub, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills section ────────────────────────────────────────────────────────

  // ── Data transfer ─────────────────────────────────────────────────────────

  /// Messenger и Navigator берутся до первого await: диалог профиля может
  /// закрыться, пока пользователь выбирает файл.
  Widget _buildDataTransfer(
    BuildContext context,
    AppState state,
    bool isDark,
    Color txt,
    Color sub,
    Color bdr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubLbl('Данные', sub),
        const SizedBox(height: 10),
        Text(
          'Один файл со всеми навыками, квестами, историей и настройками. '
          'Экспортируйте на одном устройстве и импортируйте на другом.',
          style: TextStyle(color: sub, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 12),
        UserDataTransferControls(state: state, popOnImport: true),
      ],
    );
  }

  static String _openTaskLabel(int count) {
    if (count == 0) return 'Пусто';
    final tail = count % 100;
    final last = count % 10;
    final word = tail >= 11 && tail <= 14
        ? 'задач'
        : last == 1
        ? 'задача'
        : last >= 2 && last <= 4
        ? 'задачи'
        : 'задач';
    return '$count $word';
  }

  Widget _buildSkillsSection(
    BuildContext context,
    AppState s,
    bool isDark,
    Color txt,
    Color sub,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubLbl('Навыки', sub),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: s.skills.map((sk) {
              final inbox = sk.id == kInboxSkillId;
              final openTasks = inbox
                  ? s.inboxTasks.where((task) => !task.isDone).length
                  : 0;
              return SizedBox(
                // Плитки одного размера: раньше ширина зависела от длины
                // названия, и ряд навыков выглядел рваным.
                width: widget.fullScreen ? constraints.maxWidth : 158,
                child: Tooltip(
                  message: inbox
                      ? 'Открыть Задачник'
                      : 'Перейти к навыку “${sk.name}”',
                  child: GestureDetector(
                    onTap: () {
                      s.selectSkill(sk.id);
                      Navigator.pop(context);
                    },
                    child: _SkillChip(
                      skill: sk,
                      isDark: isDark,
                      expanded: widget.fullScreen,
                      // У Задачника нет ни опыта, ни уровня: это быстрые
                      // дела вне навыков. Показываем то, что там правда есть.
                      meta: inbox
                          ? _openTaskLabel(openTasks)
                          : 'Ур. ${sk.level} · ${(sk.progress * 100).round()}%',
                      progress: inbox ? null : sk.progress,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _skillWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'навык';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'навыка';
    }
    return 'навыков';
  }
}

class _ProfileTimelineButton extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Color txt;
  final Color sub;
  final bool fullScreen;

  const _ProfileTimelineButton({
    required this.state,
    required this.isDark,
    required this.txt,
    required this.sub,
    required this.fullScreen,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFAF52DE);

    return PressFeedback(
      scale: 0.98,
      tooltip: 'Открыть летопись роста персонажа',
      onTap: () {
        if (fullScreen) {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) =>
                  CharacterTimelineDialog(state: state, fullScreen: true),
            ),
          );
          return;
        }
        showDialog(
          context: context,
          builder: (_) => CharacterTimelineDialog(state: state),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withAlpha(isDark ? 18 : 12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withAlpha(isDark ? 58 : 44)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withAlpha(24),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.auto_stories, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Летопись роста',
                    style: TextStyle(
                      color: txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Уровни, сопротивление, освоение и сильные недели',
                    style: TextStyle(color: sub, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: sub.withAlpha(180), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsToggle extends StatelessWidget {
  const _ProfileSettingsToggle({
    required this.background,
    required this.border,
    required this.text,
    required this.secondary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color secondary;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: value ? const Color(0xFF4A9EFF) : secondary.withAlpha(150),
          size: 17,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: secondary, fontSize: 11.5),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF4A9EFF),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

// ─── Skill chip (in profile) ──────────────────────────────────────────────────

class _SkillChip extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  final bool expanded;

  /// Вторая строка плитки: уровень с процентом либо число открытых задач.
  final String meta;

  /// Полоса прогресса. `null` там, где прогресса нет — у Задачника.
  final double? progress;

  const _SkillChip({
    required this.skill,
    required this.isDark,
    required this.meta,
    required this.progress,
    this.expanded = false,
  });
  @override
  State<_SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<_SkillChip> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    final sk = widget.skill;
    final sub = subtext(widget.isDark);

    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.96 : 1.0,
        duration: kMotionFast,
        curve: kMotionCurve,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: sk.color.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sk.color.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(sk.icon, color: sk.color, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sk.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: sk.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: sub, fontSize: 10.5),
              ),
              const SizedBox(height: 6),
              // Полоса рисуется всегда — иначе плитки разъезжались бы по
              // высоте. У Задачника она пустая и приглушённая.
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: widget.progress ?? 0,
                  minHeight: 3,
                  backgroundColor: sk.color.withAlpha(
                    widget.progress == null ? 16 : 30,
                  ),
                  valueColor: AlwaysStoppedAnimation(sk.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
