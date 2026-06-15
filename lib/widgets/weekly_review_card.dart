import 'package:flutter/material.dart';

import '../app_state.dart';
import '../engines/review_engine.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class WeeklyReviewCard extends StatefulWidget {
  final AppState state;
  final bool isDark;

  const WeeklyReviewCard({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  State<WeeklyReviewCard> createState() => _WeeklyReviewCardState();
}

class _WeeklyReviewCardState extends State<WeeklyReviewCard> {
  static const _engine = ReviewEngine();

  final _winsCtrl = TextEditingController();
  final _blockersCtrl = TextEditingController();
  final _adjustmentCtrl = TextEditingController();
  final _nextFocusCtrl = TextEditingController();

  bool _expanded = false;
  bool _dismissed = false;
  String? _syncedSkillId;
  int? _syncedReviewCount;

  @override
  void dispose() {
    _winsCtrl.dispose();
    _blockersCtrl.dispose();
    _adjustmentCtrl.dispose();
    _nextFocusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final suggestion = _engine.suggestPrimary(
      widget.state.skills,
      widget.state.history,
    );
    if (suggestion == null) return const SizedBox.shrink();

    _syncControllers(suggestion);

    final isDark = widget.isDark;
    final color = suggestion.skill.color;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final statusText = suggestion.isDue
        ? 'пора коротко подвести неделю'
        : 'review пока не горит';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressFeedback(
            onTap: () => setState(() => _expanded = !_expanded),
            tooltip: _expanded ? 'Свернуть review' : 'Подвести неделю',
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.rate_review, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review цели',
                        style: TextStyle(
                          color: txt,
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${suggestion.skill.name} · $statusText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: sub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskBadge(
                icon: Icons.check_circle,
                label: '${suggestion.recentQuestCount} квест.',
                color: const Color(0xFF34C759),
              ),
              TaskBadge(
                icon: Icons.auto_awesome,
                label: '+${suggestion.recentXp} XP',
                color: const Color(0xFF4A9EFF),
              ),
              if (suggestion.lastReviewAt != null)
                TaskBadge(
                  icon: Icons.history,
                  label: formatShortDate(suggestion.lastReviewAt!),
                  color: const Color(0xFF8E8E93),
                ),
            ],
          ),
          if (!_expanded) ...[
            const SizedBox(height: 9),
            Text(
              suggestion.winsDraft,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: sub,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 12),
            _ReviewField(
              controller: _winsCtrl,
              label: 'Что получилось',
              hint: 'Победы, закрытые квесты, XP',
              isDark: isDark,
            ),
            const SizedBox(height: 9),
            _ReviewField(
              controller: _blockersCtrl,
              label: 'Что мешало',
              hint: 'Без самокритики: только факты',
              isDark: isDark,
            ),
            const SizedBox(height: 9),
            _ReviewField(
              controller: _adjustmentCtrl,
              label: 'Что скорректировать',
              hint: 'Упростить, перенести, изменить план',
              isDark: isDark,
            ),
            const SizedBox(height: 9),
            _ReviewField(
              controller: _nextFocusCtrl,
              label: 'Следующий фокус',
              hint: 'Один ориентир на неделю',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SmallBtn(
                    label: 'Сохранить review',
                    icon: Icons.check,
                    color: color,
                    onTap: () => _saveReview(context, suggestion.skill),
                  ),
                ),
                const SizedBox(width: 10),
                PressFeedback(
                  scale: 0.94,
                  tooltip: 'Напомнить завтра',
                  onTap: () => setState(() => _dismissed = true),
                  child: Text(
                    'Завтра',
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _syncControllers(ReviewSuggestion suggestion) {
    final reviewCount = suggestion.skill.goalSpec.reviews.length;
    if (_syncedSkillId == suggestion.skill.id &&
        _syncedReviewCount == reviewCount) {
      return;
    }

    _syncedSkillId = suggestion.skill.id;
    _syncedReviewCount = reviewCount;
    _winsCtrl.text = suggestion.winsDraft;
    _blockersCtrl.text = suggestion.blockersDraft;
    _adjustmentCtrl.text = suggestion.adjustmentDraft;
    _nextFocusCtrl.text = suggestion.nextFocusDraft;
  }

  void _saveReview(BuildContext context, Skill skill) {
    final review = GoalReviewEntry(
      id: uid(),
      wins: _winsCtrl.text.trim(),
      blockers: _blockersCtrl.text.trim(),
      adjustment: _adjustmentCtrl.text.trim(),
      nextFocus: _nextFocusCtrl.text.trim(),
      updatedPlan:
          _adjustmentCtrl.text.trim().isNotEmpty ||
          _nextFocusCtrl.text.trim().isNotEmpty,
    );

    widget.state.addGoalReview(skill.id, review);
    setState(() => _expanded = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Review сохранён в историю цели')),
    );
  }
}

class _ReviewField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;

  const _ReviewField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      style: TextStyle(
        color: textColor(isDark),
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: isDark ? const Color(0xFF15151C) : const Color(0xFFF7F7FA),
        labelStyle: TextStyle(color: subtext(isDark), fontSize: 12),
        hintStyle: TextStyle(color: subtext(isDark).withAlpha(150)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A9EFF)),
        ),
      ),
    );
  }
}
