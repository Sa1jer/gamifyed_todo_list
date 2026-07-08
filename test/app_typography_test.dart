import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/theme/app_typography.dart';

void main() {
  test('semantic typography keeps a short stable application scale', () {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: Brightness.dark,
    );
    final textTheme = AppTypography.textTheme(scheme);

    expect(textTheme.headlineSmall?.fontSize, 20);
    expect(textTheme.titleLarge?.fontSize, 18);
    expect(textTheme.titleMedium?.fontSize, 15.5);
    expect(textTheme.titleSmall?.fontSize, 13.5);
    expect(textTheme.bodyMedium?.fontSize, 13);
    expect(textTheme.bodySmall?.fontSize, 11.5);
    expect(textTheme.labelLarge?.fontSize, 13);
    expect(textTheme.labelMedium?.fontSize, 11);
    expect(textTheme.labelSmall?.fontSize, 10.5);
  });

  testWidgets('theme extension exposes product semantic roles', (tester) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A9EFF),
      brightness: Brightness.light,
    );
    final textTheme = AppTypography.textTheme(scheme);
    late AppTextRoles roles;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          textTheme: textTheme,
          extensions: [
            AppTextRoles.fromTheme(textTheme, brightness: Brightness.light),
          ],
        ),
        home: Builder(
          builder: (context) {
            roles = context.appTextRoles;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(roles.reward.fontWeight, FontWeight.w900);
    expect(roles.statValue.fontSize, textTheme.titleLarge?.fontSize);
    expect(roles.sectionEyebrow.letterSpacing, 0.7);
    expect(roles.compactMetadata.fontSize, textTheme.labelMedium?.fontSize);
  });

  testWidgets('semantic roles survive a nested Theme without extensions', (
    tester,
  ) async {
    late AppTextRoles nestedRoles;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Theme(
          data: ThemeData.dark(),
          child: Builder(
            builder: (context) {
              nestedRoles = context.appTextRoles;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(nestedRoles.reward.color, const Color(0xFFFFC21A));
    expect(nestedRoles.sectionEyebrow.fontWeight, FontWeight.w900);
  });
}
