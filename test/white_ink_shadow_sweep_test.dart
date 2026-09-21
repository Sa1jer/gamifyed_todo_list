import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Белый текст и белые иконки лежат на цвете, который выбирает пользователь.
/// На светлых цветах контраст падает примерно до 1.5:1 при пороге 4.5, и
/// владелец выбрал единообразный белый, зная это. Тень — единственное, что
/// возвращает читаемость, не трогая его решение.
///
/// Тест сторожит охват: без него следующий белый текст просто забудут.
void main() {
  test('every white ink carries the shadow', () {
    final offenders = <String>[];
    final style = RegExp(
      r'(TextStyle|Icon)\((?:[^()]|\([^()]*\))*?Colors\.white'
      r'(?:[^()]|\([^()]*\))*?\)',
      dotAll: true,
    );

    for (final file in Directory('lib').listSync(recursive: true)) {
      // Отладочная панель в сборку не попадает.
      if (file is! File ||
          !file.path.endsWith('.dart') ||
          file.path.startsWith('lib/debug/')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final match in style.allMatches(source)) {
        final body = match.group(0)!;
        if (body.contains('shadows:')) continue;
        // Счётчик задач: белый там условный и на обычной поверхности, а не
        // на цветной подложке — тень была бы грязью.
        if (body.contains('Colors.white.withAlpha')) continue;
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'белое без тени:\n${offenders.join('\n')}',
    );
  });
}
