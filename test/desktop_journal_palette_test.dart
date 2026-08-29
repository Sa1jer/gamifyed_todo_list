import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/desktop_journal_tokens.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance() + 0.05;
  final y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}

Color _over(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

void main() {
  group('светлая палитра desktop', () {
    final tokens = DesktopJournalTokens.resolve(false);

    test('чернильные роли читаемы на карточке и на фоне', () {
      // Прежние значения не проходили AA: золото #B47700 давало 3.76:1.
      // rewardGold сюда не входит: владелец выбрал блестящий жёлтый
      // #FFCF40 вместо цвета, проходящего AA. См. отдельную проверку ниже —
      // она фиксирует выбор, чтобы он не выглядел недосмотром.
      for (final entry in {
        'successGreen': tokens.successGreen,
        'streakAmber': tokens.streakAmber,
      }.entries) {
        expect(
          _contrast(entry.value, tokens.cardSurface),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} на карточке',
        );
        expect(
          _contrast(entry.value, tokens.mainSurface),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} на фоне рабочей области',
        );
      }
    });

    test('чернильные роли читаемы на собственной тонированной карточке', () {
      // Карточка трофея заливается самим чернильным цветом на 5.5% и несёт
      // на себе его же текст — самый тёмный фон под этими цветами.
      for (final entry in {
        'successGreen': tokens.successGreen,
        'streakAmber': tokens.streakAmber,
      }.entries) {
        final tinted = _over(
          entry.value.withValues(alpha: 0.055),
          tokens.cardSurface,
        );
        expect(
          _contrast(entry.value, tinted),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} на собственной заливке',
        );
      }
    });

    test('графические роли держат 3:1 — порог для нетекстовой графики', () {
      for (final entry in {
        'successGreenGraphic': tokens.successGreenGraphic,
        'streakAmberGraphic': tokens.streakAmberGraphic,
      }.entries) {
        expect(
          _contrast(entry.value, tokens.cardSurface),
          greaterThanOrEqualTo(3),
          reason: entry.key,
        );
      }
    });

    test('графические роли заметно ярче чернильных', () {
      // Смысл разделения: пилюли, иконки и полосы остаются золотыми и
      // зелёными, а текст на них уходит вглубь ровно настолько, чтобы
      // читаться. Если яркости сойдутся, разделение потеряет смысл.
      expect(
        tokens.successGreenGraphic.computeLuminance(),
        greaterThan(tokens.successGreen.computeLuminance()),
      );
      expect(
        tokens.streakAmberGraphic.computeLuminance(),
        greaterThan(tokens.streakAmber.computeLuminance()),
      );
    });
  });

  test('золото — осознанный выбор владельца, а не промах по контрасту', () {
    // Блестящий жёлтый hsl(45, 100%, 63%). На белом это 1.55:1 — ниже AA.
    // Тест фиксирует решение: если цвет когда-нибудь поедет, станет видно,
    // что это правка, а не случайная регрессия.
    final light = DesktopJournalTokens.resolve(false);
    expect(light.rewardGold, const Color(0xFFFFCF40));
    expect(light.rewardGoldGraphic, light.rewardGold);
    expect(_contrast(light.rewardGold, light.cardSurface), lessThan(2));
  });

  test('в тёмной теме графическая и чернильная роли совпадают', () {
    final dark = DesktopJournalTokens.resolve(true);
    expect(dark.rewardGoldGraphic, dark.rewardGold);
    expect(dark.successGreenGraphic, dark.successGreen);
    expect(dark.streakAmberGraphic, dark.streakAmber);
  });
}
