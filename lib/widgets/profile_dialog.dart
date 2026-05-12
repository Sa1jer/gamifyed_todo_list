// To-Do List RPG — Profile Dialog
// Requires: file_picker: ^8.1.0 in pubspec.yaml
// macOS entitlements: com.apple.security.files.user-selected.read-only = true

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    return result?.files.single.bytes;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final p = s.profile;
    final profileRank = profileRankForLevel(p.level);
    final isDark = s.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 460,
          constraints: const BoxConstraints(maxHeight: 680),
          color: bg,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Banner ─────────────────────────────────────────────────
                  _buildBannerSection(context, s, p),
                  // ── Scrollable Body ───────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameRow(context, s, p, txt, sub),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              RankBadge(
                                label: profileRank.label,
                                color: profileRank.color,
                              ),
                              const SizedBox(width: 8),
                              LvlBadge(
                                level: p.level,
                                color: const Color(0xFF4A9EFF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(height: 1, color: bdr),
                          const SizedBox(height: 14),
                          _buildXPSection(p, sub),
                          const SizedBox(height: 6),
                          _buildTotalXP(p, txt, sub),
                          const SizedBox(height: 4),
                          Text(
                            'Изучаю ${s.activeSkillCount} ${_skillWord(s.activeSkillCount)}',
                            style: TextStyle(color: sub, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          Container(height: 1, color: bdr),
                          const SizedBox(height: 14),
                          _buildPersonalInfo(
                            context,
                            s,
                            p,
                            isDark,
                            txt,
                            sub,
                            bdr,
                          ),
                          const SizedBox(height: 18),
                          Container(height: 1, color: bdr),
                          const SizedBox(height: 14),
                          _buildSkillsSection(context, s, isDark, txt, sub),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Keep avatar above the scrollable body during scroll.
              Positioned(
                top: 120,
                left: 24,
                child: _buildAvatar(context, s, p, isDark),
              ),
            ],
          ),
        ),
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
          // Banner
          Tooltip(
            message: 'Изменить баннер профиля',
            child: GestureDetector(
              onTap: () async {
                final bytes = await _pickImage();
                if (bytes != null && context.mounted) {
                  s.updateProfileBanner(bytes);
                }
              },
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: p.bannerBytes != null
                        ? Image.memory(p.bannerBytes!, fit: BoxFit.cover)
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
                  // Dim overlay + hint
                  Positioned.fill(
                    child: Container(
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
          ),
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

  Widget _buildAvatar(
    BuildContext context,
    AppState s,
    UserProfile p,
    bool isDark,
  ) {
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
                        image: MemoryImage(p.avatarBytes!),
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
                          fontWeight: FontWeight.bold,
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
    Color sub,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 50), // offset for avatar overlap
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_editingName)
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
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

  Widget _buildXPSection(UserProfile p, Color sub) {
    final currentRank = profileRankForLevel(p.level);
    final nextRank = nextProfileRankForLevel(p.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          nextRank == null
              ? 'Текущий ранг: ${currentRank.label}. Пиковый ранг уже достигнут.'
              : 'Текущий ранг: ${currentRank.label}. Следующий — ${nextRank.label} на ур.${nextRank.minLevel}.',
          style: TextStyle(color: sub, fontSize: 12, height: 1.25),
        ),
      ],
    );
  }

  Widget _buildTotalXP(UserProfile p, Color txt, Color sub) {
    return Row(
      children: [
        Text('Всего опыта', style: TextStyle(color: sub, fontSize: 13)),
        const Spacer(),
        Text(
          '${p.totalXpEarned}',
          style: TextStyle(
            color: txt,
            fontSize: 15,
            fontWeight: FontWeight.bold,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubLbl('Личные данные', sub),
        const SizedBox(height: 10),
        Row(
          children: [
            // Age field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bdr),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: txt, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Возраст',
                          hintStyle: TextStyle(color: sub, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          final age = int.tryParse(v.trim());
                          s.updateProfileAge(age);
                        },
                        onSubmitted: (v) {
                          final age = int.tryParse(v.trim());
                          s.updateProfileAge(age);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Gender picker
            Expanded(
              child: Tooltip(
                message: 'Выбрать пол',
                child: GestureDetector(
                  onTap: () => _showGenderPicker(context, s, p, isDark, sub),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: fBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bdr),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.gender != null ? genderLabel[p.gender]! : 'Пол',
                            style: TextStyle(
                              color: p.gender != null ? txt : sub,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: sub, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

  // ── Skills section ────────────────────────────────────────────────────────

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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: s.skills
              .map(
                (sk) => Tooltip(
                  message: 'Перейти к навыку “${sk.name}”',
                  child: GestureDetector(
                    onTap: () {
                      s.selectSkill(sk.id);
                      Navigator.pop(context);
                    },
                    child: _SkillChip(skill: sk, isDark: isDark),
                  ),
                ),
              )
              .toList(),
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

// ─── Skill chip (in profile) ──────────────────────────────────────────────────

class _SkillChip extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  const _SkillChip({required this.skill, required this.isDark});
  @override
  State<_SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<_SkillChip> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    final sk = widget.skill;
    final skillRank = skillRankForLevel(sk.level);
    final sub = subtext(widget.isDark);

    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sk.color.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sk.color.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sk.icon, color: sk.color, size: 14),
              const SizedBox(width: 6),
              Text(
                sk.name,
                style: TextStyle(
                  color: sk.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skillRank.label,
                    style: TextStyle(color: sub, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Ур.${sk.level}',
                    style: TextStyle(color: sub.withAlpha(190), fontSize: 9.5),
                  ),
                  SizedBox(
                    width: 78,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: sk.progress,
                        minHeight: 3,
                        backgroundColor: sk.color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation(sk.color),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
