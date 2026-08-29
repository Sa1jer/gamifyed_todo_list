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
      for (final entry in {
        'rewardGold': tokens.rewardGold,
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

    test('чернильные роли читаемы на собственной подложке-пилюле', () {
      for (final entry in {
        'rewardGold': (tokens.rewardGold, tokens.rewardGoldGraphic),
        'successGreen': (tokens.successGreen, tokens.successGreenGraphic),
        'streakAmber': (tokens.streakAmber, tokens.streakAmberGraphic),
      }.entries) {
        final (ink, graphic) = entry.value;
        final pill = _over(graphic.withValues(alpha: 0.14), tokens.cardSurface);
        expect(
          _contrast(ink, pill),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} на пилюле',
        );
      }
    });

    test('графические роли держат 3:1 — порог для нетекстовой графики', () {
      for (final entry in {
        'rewardGoldGraphic': tokens.rewardGoldGraphic,
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
        tokens.rewardGoldGraphic.computeLuminance(),
        greaterThan(tokens.rewardGold.computeLuminance()),
      );
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

  test('в тёмной теме графическая и чернильная роли совпадают', () {
    final dark = DesktopJournalTokens.resolve(true);
    expect(dark.rewardGoldGraphic, dark.rewardGold);
    expect(dark.successGreenGraphic, dark.successGreen);
    expect(dark.streakAmberGraphic, dark.streakAmber);
  });
}
