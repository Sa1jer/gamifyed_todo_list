import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../utils.dart';
import '../mobile_journal_tokens.dart';
import '../shared/motion_controls.dart';

class SkillCreatorNameError extends StatelessWidget {
  const SkillCreatorNameError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: const ValueKey('add-skill-name-error'),
      style: const TextStyle(
        color: Color(0xFFFF453A),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class DesktopSkillIdentityPreview extends StatelessWidget {
  const DesktopSkillIdentityPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.goal,
    required this.isDark,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String goal;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('desktop-skill-live-preview'),
          width: 190,
          constraints: const BoxConstraints(minHeight: 204),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 24 : 14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                key: const ValueKey('skill-preview-icon'),
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 34 : 24),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withAlpha(130), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 38),
              ),
              const SizedBox(height: 14),
              Text(
                name.trim().isEmpty ? 'Новый навык' : name.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: name.trim().isEmpty
                      ? subtext(isDark)
                      : textColor(isDark),
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                goal.trim().isEmpty ? 'Цель появится здесь' : goal.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: child),
      ],
    );
  }
}

class MobileSkillEmblemPreview extends StatelessWidget {
  const MobileSkillEmblemPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MobileMotion.reduced(
      context,
      appReducedMotion:
          AppStateProvider.maybeOf(context)?.reducedMotion ?? false,
    );
    final displayName = name.trim().isEmpty ? 'Твой новый навык' : name.trim();

    return Center(
      child: Column(
        children: [
          AnimatedContainer(
            key: const ValueKey('skill-preview-icon'),
            duration: reduceMotion ? Duration.zero : kMotionSlow,
            curve: kMotionCurve,
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 24 : 16),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: color.withAlpha(150), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(isDark ? 46 : 30),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : kMotionStandard,
              child: Icon(
                icon,
                key: ValueKey(icon.codePoint),
                color: color,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : kMotionStandard,
            child: Text(
              displayName,
              key: ValueKey(displayName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: name.trim().isEmpty
                    ? subtext(isDark)
                    : textColor(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileSkillFormSection extends StatelessWidget {
  const MobileSkillFormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.isNotEmpty;
    return Column(
      key: ValueKey('mobile-skill-section-$title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: hasSubtitle ? 14.5 : 15.5,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
