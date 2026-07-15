import 'dart:io';

const _largestFileCount = 15;

Future<void> main() async {
  final root = Directory.current;
  final lib = Directory('${root.path}${Platform.pathSeparator}lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run this command from the repository root.');
    exitCode = 2;
    return;
  }

  final dartFiles = lib
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final measurements = <_FileMeasurement>[];
  final violations = <String>[];

  for (final file in dartFiles) {
    final relative = _relativePath(root, file);
    final source = await file.readAsString();
    measurements.add(
      _FileMeasurement(relative, '\n'.allMatches(source).length + 1),
    );

    if (relative.startsWith('lib/analytics/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
      _forbidLiveModelField(relative, source, violations);
    }
    if (relative.startsWith('lib/coordinators/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, '/widgets/', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
    }
    if (relative.startsWith('lib/persistence/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, '/widgets/', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
    }
  }

  measurements.sort((a, b) => b.lines.compareTo(a.lines));
  stdout.writeln('Largest $_largestFileCount Dart files:');
  for (final item in measurements.take(_largestFileCount)) {
    stdout.writeln('${item.lines.toString().padLeft(5)}  ${item.path}');
  }

  final appState = measurements
      .where((item) => item.path == 'lib/app_state.dart')
      .firstOrNull;
  if (appState != null) {
    stdout.writeln('\nAppState: ${appState.lines} lines');
  }

  final modelsBarrel = File('${lib.path}${Platform.pathSeparator}models.dart');
  if (modelsBarrel.existsSync()) {
    final source = await modelsBarrel.readAsString();
    if (RegExp(
      r'^\s*(class|enum|mixin)\s+',
      multiLine: true,
    ).hasMatch(source)) {
      violations.add(
        'lib/models.dart must remain a compatibility export barrel; '
        'model declarations belong in lib/models/.',
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('\nArchitecture boundaries: OK');
    return;
  }
  stderr.writeln('\nArchitecture boundary violations:');
  for (final violation in violations) {
    stderr.writeln('- $violation');
  }
  exitCode = 1;
}

void _forbidImport(
  String path,
  String source,
  String fragment,
  List<String> violations,
) {
  final imports = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true)
      .allMatches(source)
      .map((match) => match.group(1)!)
      .where((value) => value.contains(fragment));
  for (final import in imports) {
    violations.add('$path imports forbidden dependency $import.');
  }
}

void _forbidLiveModelField(
  String path,
  String source,
  List<String> violations,
) {
  final field = RegExp(
    r'^\s*final\s+(Task|Skill|WeeklyGoal|HistoryEntry)\??\s+\w+\s*;',
    multiLine: true,
  ).firstMatch(source);
  if (field != null) {
    violations.add(
      '$path retains mutable ${field.group(1)} instances in an analytics '
      'output; project scalar snapshot data instead.',
    );
  }
}

String _relativePath(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  return file.path
      .substring(prefix.length)
      .replaceAll(Platform.pathSeparator, '/');
}

class _FileMeasurement {
  final String path;
  final int lines;

  const _FileMeasurement(this.path, this.lines);
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
