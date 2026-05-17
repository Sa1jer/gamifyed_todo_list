import 'package:flutter/material.dart';
import '../utils.dart';
import 'shared.dart';

class FAQDialog extends StatelessWidget {
  final bool isDark;

  const FAQDialog({super.key, required this.isDark});

  static const _sections = <_FAQSection>[
    _FAQSection(
      icon: Icons.route,
      color: Color(0xFF4A9EFF),
      title: 'Главная идея',
      subtitle: 'Это не просто список дел, а система прокачки жизни.',
      bullets: [
        'Навык — направление развития: Python, спорт, проект, привычка.',
        'Квест — конкретное действие, которое двигает навык вперёд.',
        'XP, уровни и ранги показывают реальный накопленный прогресс.',
      ],
    ),
    _FAQSection(
      icon: Icons.auto_awesome,
      color: Color(0xFFFFCC00),
      title: 'Сегодня',
      subtitle: 'Главный блок отвечает на вопрос: “что делать сейчас?”',
      bullets: [
        'Следующий шаг выбирается из активных квестов по приоритету, типу и XP.',
        'Мини-статистика показывает XP, выполненные и повторяющиеся квесты.',
        'Если есть лёгкий старт, приложение может предложить начать с минимума.',
      ],
    ),
    _FAQSection(
      icon: Icons.flag,
      color: Color(0xFF34C759),
      title: 'Квесты и лёгкий старт',
      subtitle: 'Anti-procrastination слой помогает начать без давления.',
      bullets: [
        'Обычное выполнение закрывает задачу и выдаёт полную награду.',
        'Минимальное действие даёт часть XP и помечает задачу как начатую.',
        'У повторяющихся задач лёгкий старт может закрыть квест дня.',
      ],
    ),
    _FAQSection(
      icon: Icons.bolt,
      color: Color(0xFFFF9500),
      title: 'XP, уровни и ранги',
      subtitle: 'Каждый закрытый квест усиливает профиль и связанный навык.',
      bullets: [
        'XP профиля показывает общий прогресс персонажа.',
        'XP навыка показывает прогресс в конкретном направлении.',
        'Ранги добавляют эмоциональную ступень: от новичка к более сильным тайтлам.',
      ],
    ),
    _FAQSection(
      icon: Icons.redeem,
      color: Color(0xFFAF52DE),
      title: 'Сундуки и баффы',
      subtitle:
          'Награды дают мягкое усиление, а не превращают систему в казино.',
      bullets: [
        'Сундуки выдаются за дневной темп, серии и победы над боссами.',
        'Открытый сундук создаёт бафф: бонус XP на следующий квест или серию.',
        'Если отменить квест, награда откатывается, когда её условие больше не выполнено.',
      ],
    ),
    _FAQSection(
      icon: Icons.shield,
      color: Color(0xFFFF2D55),
      title: 'Боссы',
      subtitle: 'Босс — образ плохой привычки или сопротивления.',
      bullets: [
        'Босс слабеет от выполненных квестов, лёгкого старта, чеклистов и дерева навыков.',
        'High-priority задачи под давлением усиливают ощущение атаки босса.',
        'Победа над боссом даёт сундук, но отмена победного квеста может вернуть босса.',
      ],
    ),
    _FAQSection(
      icon: Icons.account_tree,
      color: Color(0xFF5AC8FA),
      title: 'Дерево навыков',
      subtitle: 'Большой навык можно разложить на узлы мастерства.',
      bullets: [
        'Узел может быть закрыт, активен или освоен.',
        'Prerequisites открывают следующий шаг только после освоения предыдущего.',
        'Освоение узлов даёт XP и помогает прогрессу против боссов.',
      ],
    ),
    _FAQSection(
      icon: Icons.calendar_month,
      color: Color(0xFF30D158),
      title: 'Календарь и история',
      subtitle: 'Приложение отслеживает, когда именно был закрыт квест.',
      bullets: [
        'Календарь подсвечивает дни с фактическими выполнениями.',
        'Отмена выполнения добавляет обратную запись и убирает день из эффективной истории.',
        'История помогает проверить, за что начислялся или откатывался XP.',
      ],
    ),
  ];

  static const _quickStart = <String>[
    'Создай 2–3 навыка, которые реально хочешь прокачивать.',
    'Для каждого навыка добавь одну понятную цель.',
    'Создай маленькие квесты и хотя бы один повторяющийся квест.',
    'Для крупной задачи добавь “Минимальное действие”.',
    'Каждый день начинай с блока “Сегодня”, а не со всего списка.',
  ];

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(360.0, 820.0);
          final height = MediaQuery.sizeOf(context).height.clamp(520.0, 680.0);

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: bdr),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 120 : 40),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9EFF).withAlpha(26),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Color(0xFF4A9EFF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Гид по RPG To-Do List',
                              style: TextStyle(
                                color: txt,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Коротко о том, как работает прокачка, квесты и награды.',
                              style: TextStyle(
                                color: sub,
                                fontSize: 12.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PressFeedback(
                        scale: 0.94,
                        tooltip: 'Закрыть гид',
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: sub, size: 22),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: bdr),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    children: [
                      _QuickStartCard(
                        isDark: isDark,
                        titleColor: txt,
                        subtitleColor: sub,
                        items: _quickStart,
                      ),
                      const SizedBox(height: 14),
                      for (final section in _sections) ...[
                        _FAQSectionCard(section: section, isDark: isDark),
                        const SizedBox(height: 10),
                      ],
                      _FAQHintCard(isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FAQSection {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> bullets;

  const _FAQSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
}

class _QuickStartCard extends StatelessWidget {
  final bool isDark;
  final Color titleColor;
  final Color subtitleColor;
  final List<String> items;

  const _QuickStartCard({
    required this.isDark,
    required this.titleColor,
    required this.subtitleColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF101C2F), Color(0xFF17131F)]
              : const [Color(0xFFEAF3FF), Color(0xFFFFF7E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle, color: Color(0xFF4A9EFF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Быстрый старт',
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Если открываешь приложение впервые или после паузы, начни отсюда:',
            style: TextStyle(color: subtitleColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: [
              for (var i = 0; i < items.length; i++)
                _StepPill(index: i + 1, label: items[i], isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final int index;
  final String label;
  final bool isDark;

  const _StepPill({
    required this.index,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(12)
            : Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFF4A9EFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              label,
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQSectionCard extends StatelessWidget {
  final _FAQSection section;
  final bool isDark;

  const _FAQSectionCard({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: section.color.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(section.icon, color: section.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    color: txt,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  section.subtitle,
                  style: TextStyle(color: sub, fontSize: 12.5, height: 1.3),
                ),
                const SizedBox(height: 10),
                for (final bullet in section.bullets)
                  _BulletLine(
                    text: bullet,
                    color: section.color,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _BulletLine({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor(isDark).withAlpha(isDark ? 215 : 220),
                fontSize: 12.4,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQHintCard extends StatelessWidget {
  final bool isDark;

  const _FAQHintCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withAlpha(16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34C759).withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tips_and_updates,
            color: Color(0xFF34C759),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Лучший режим использования: не планировать идеально, а каждый день закрывать хотя бы один маленький квест. Система сильнее всего работает, когда помогает начать.',
              style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
