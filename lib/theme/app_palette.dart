import 'package:flutter/material.dart';

/// Пять смысловых ролей цвета — единственное место, где они заданы.
///
/// Это фундамент под сменные темы, а не косметика. Сейчас тема одна и роли
/// прибиты к светлой и тёмной паре; когда тем станет несколько, подменяется
/// один объект [AppPalette], а весь интерфейс, читающий роли, переезжает
/// вместе с ним. Каждый литерал `Color(0xFF…)`, оставшийся в виджете, — это
/// место, которое тема перекрасить не сможет.
///
/// Роли (P1-06 аудита):
///
///  * [accent] — системный акцент: то, что принадлежит приложению, а не навыку
///  * [reward] — XP и награды
///  * [success] — выполнено
///  * [danger] — удаление и ошибка
///  * [neutral] — всё остальное
///
/// У награды и успеха по два оттенка. `ink` — для текста, он темнее и проходит
/// по контрасту; `graphic` — для иконок, обводок и полос, где порог ниже (3:1
/// против 4.5:1) и можно взять цвет чище. Разводить их пришлось на светлой
/// теме: золото, читаемое как текст на белом, неизбежно уходит в коричневый.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color accent;
  final Color rewardInk;
  final Color rewardGraphic;
  final Color successInk;
  final Color successGraphic;
  final Color streakInk;
  final Color streakGraphic;
  final Color danger;
  final Color neutral;

  const AppPalette({
    required this.accent,
    required this.rewardInk,
    required this.rewardGraphic,
    required this.successInk,
    required this.successGraphic,
    required this.streakInk,
    required this.streakGraphic,
    required this.danger,
    required this.neutral,
  });

  /// Светлая пара.
  ///
  /// `rewardInk` — решение владельца: «блестящий жёлтый» `#FFCF40` даёт 1.55:1
  /// на белом и AA не проходит. Выбран ради узнаваемого золота, менять без
  /// его слова не нужно.
  static const light = AppPalette(
    // Светлый акцент темнее тёмного: на белом `#765BFF` слишком звонкий.
    // Сводить их к одному цвету нельзя — это разные решения, а не дубль.
    accent: Color(0xFF6D55E8),
    rewardInk: Color(0xFFFFCF40),
    rewardGraphic: Color(0xFFFFCF40),
    successInk: Color(0xFF00802F),
    successGraphic: Color(0xFF00A83E),
    streakInk: Color(0xFFB25300),
    streakGraphic: Color(0xFFEB6D00),
    danger: Color(0xFFD83651),
    neutral: Color(0xFF8E8E93),
  );

  static const dark = AppPalette(
    accent: Color(0xFF765BFF),
    rewardInk: Color(0xFFFFC21A),
    rewardGraphic: Color(0xFFFFC21A),
    successInk: Color(0xFF2ED36F),
    successGraphic: Color(0xFF2ED36F),
    streakInk: Color(0xFFFF8A1F),
    streakGraphic: Color(0xFFFF8A1F),
    danger: Color(0xFFFF315B),
    neutral: Color(0xFF8E8E93),
  );

  static AppPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Палитра текущей темы. Если тема её не объявила — пара по яркости, чтобы
  /// виджет не остался без цвета на полпути миграции.
  static AppPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppPalette>() ?? forBrightness(theme.brightness);
  }

  @override
  AppPalette copyWith({
    Color? accent,
    Color? rewardInk,
    Color? rewardGraphic,
    Color? successInk,
    Color? successGraphic,
    Color? streakInk,
    Color? streakGraphic,
    Color? danger,
    Color? neutral,
  }) => AppPalette(
    accent: accent ?? this.accent,
    rewardInk: rewardInk ?? this.rewardInk,
    rewardGraphic: rewardGraphic ?? this.rewardGraphic,
    successInk: successInk ?? this.successInk,
    successGraphic: successGraphic ?? this.successGraphic,
    streakInk: streakInk ?? this.streakInk,
    streakGraphic: streakGraphic ?? this.streakGraphic,
    danger: danger ?? this.danger,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    // Через `Color.lerp` без промежуточной прозрачности: переход к
    // `Colors.transparent` — это переход к прозрачному **чёрному**, и на
    // светлой теме он даёт серую вспышку в середине анимации.
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      rewardInk: Color.lerp(rewardInk, other.rewardInk, t)!,
      rewardGraphic: Color.lerp(rewardGraphic, other.rewardGraphic, t)!,
      successInk: Color.lerp(successInk, other.successInk, t)!,
      successGraphic: Color.lerp(successGraphic, other.successGraphic, t)!,
      streakInk: Color.lerp(streakInk, other.streakInk, t)!,
      streakGraphic: Color.lerp(streakGraphic, other.streakGraphic, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}
