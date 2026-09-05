import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  test('the version the app reports matches the version it is built as', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((line) => line.startsWith('version:'));
    final version = line.split(':')[1].trim();

    // Расходились: приложение показывало `+1`, когда собиралось как `+2`.
    // Номер сборки — это то, по чему проверка обновлений сравнивает версии,
    // так что разошедшийся ярлык означает и неверный ответ «у вас последняя».
    expect(kAppVersionLabel, 'v$version');
  });

  test('the build number can be read out of the label', () {
    expect(appBuildNumber, isNotNull);
    expect(appBuildNumber, greaterThan(0));
  });
}
