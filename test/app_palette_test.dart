import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/theme/app_palette.dart';
import 'package:todo_list_app/widgets/desktop_journal_tokens.dart';

void main() {
  /// Палитра, не совпадающая ни со светлой, ни с тёмной: так видно, что цвет
  /// пришёл из темы, а не из зашитой пары по яркости.
  const invented = AppPalette(
    accent: Color(0xFF112233),
    rewardInk: Color(0xFF445566),
    rewardGraphic: Color(0xFF778899),
    successInk: Color(0xFFAABBCC),
    successGraphic: Color(0xFFDDEEFF),
    streakInk: Color(0xFF010203),
    streakGraphic: Color(0xFF040506),
    danger: Color(0xFF070809),
    neutral: Color(0xFF0A0B0C),
  );

  Future<DesktopJournalTokens> tokensUnder(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    late DesktopJournalTokens tokens;
    // Дерево строится с нуля: иначе второй вызов с другой темой мог вернуть
    // значение, оставшееся от первого.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            tokens = DesktopJournalTokens.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return tokens;
  }

  testWidgets('a theme that supplies a palette reaches the tokens', (
    tester,
  ) async {
    final tokens = await tokensUnder(
      tester,
      ThemeData.dark().copyWith(extensions: const [invented]),
    );

    // Это и есть шов, ради которого всё затевалось: подменяется один объект,
    // и роли по всему интерфейсу едут за ним.
    expect(tokens.profilePurple, invented.accent);
    expect(tokens.rewardGold, invented.rewardInk);
    expect(tokens.rewardGoldGraphic, invented.rewardGraphic);
    expect(tokens.successGreen, invented.successInk);
    expect(tokens.streakAmber, invented.streakInk);
    expect(tokens.danger, invented.danger);
  });

  testWidgets('a theme without a palette still has colours', (tester) async {
    final dark = await tokensUnder(tester, ThemeData.dark());
    final light = await tokensUnder(tester, ThemeData.light());

    // Пока миграция не закончена, тема может не объявить палитру. Виджет не
    // должен остаться без цвета на полпути.
    expect(dark.rewardGold, AppPalette.dark.rewardInk);
    expect(light.rewardGold, AppPalette.light.rewardInk);
    expect(dark.rewardGold, isNot(light.rewardGold));
  });

  test('surfaces still follow brightness, roles follow the palette', () {
    final darkTokens = DesktopJournalTokens.resolve(true, palette: invented);
    final lightTokens = DesktopJournalTokens.resolve(false, palette: invented);

    // Поверхности — это не роли: они остаются парой светлое/тёмное, иначе
    // подменённая палитра утащила бы за собой и фон.
    expect(darkTokens.background, isNot(lightTokens.background));
    expect(darkTokens.profilePurple, lightTokens.profilePurple);
  });

  test('the five roles keep the owner decisions they encode', () {
    // Золото светлой темы — решение владельца против контраста; тёмная и
    // светлая пары не должны втихую сойтись.
    expect(AppPalette.light.rewardInk, const Color(0xFFFFCF40));
    expect(AppPalette.light.successInk, isNot(AppPalette.dark.successInk));
    expect(
      AppPalette.light.rewardGraphic,
      isNot(AppPalette.light.successGraphic),
    );
  });

  test('lerp moves through colours, never through transparent black', () {
    final middle = AppPalette.light.lerp(AppPalette.dark, 0.5);

    // Переход к `Colors.transparent` — это переход к прозрачному чёрному, и
    // на светлой теме он давал серую вспышку в середине анимации.
    expect(middle.danger.a, 1.0);
    expect(middle.accent.a, 1.0);
  });
}
