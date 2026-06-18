part of '../planning_workspace.dart';

class _InspectorHint extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InspectorHint({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 14 : 10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withAlpha(42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
}

class _SectionTitle extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dense;

  const _SectionTitle({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A9EFF), size: dense ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: dense ? 13 : 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: dense ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: dense ? 11.5 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      tooltip: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 12 : 8),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _SoftPill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 22 : 16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
