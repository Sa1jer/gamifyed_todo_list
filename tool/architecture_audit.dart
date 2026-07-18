import 'dart:io';

import 'version_sync.dart';

const _largestFileCount = 15;
const _maxProductionFileLines = 2700;
const _maxPresentationFileLines = 1350;

const _fileLineBudgets = <String, int>{
  'lib/app_state.dart': 2650,
  'lib/storage_service.dart': 500,
  'lib/widgets/shared.dart': 1000,
  'lib/widgets/main_page/desktop_workspace.dart': 250,
  'lib/widgets/weekly_analytics_dialog.dart': 400,
  'lib/widgets/progress_hub_dialog.dart': 500,
  'lib/widgets/tasks_panel.dart': 950,
  'lib/widgets/today_dashboard.dart': 1150,
};

const _ordinaryExtractedModules = <String>{
  'lib/widgets/main_page/desktop_main_workspace.dart',
  'lib/widgets/main_page/desktop_quest_row.dart',
  'lib/widgets/main_page/desktop_right_rail.dart',
  'lib/widgets/main_page/desktop_selected_skill_header.dart',
  'lib/widgets/main_page/desktop_sidebar.dart',
  'lib/widgets/main_page/desktop_workspace.dart',
  'lib/widgets/main_page/desktop_workspace_support.dart',
};

const _selectorMigratedFeatureRoots = <String>{
  'lib/widgets/tasks_panel.dart',
  'lib/widgets/today_dashboard.dart',
  'lib/widgets/mastery_map/workspace_shell.dart',
};

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
    final lines = '\n'.allMatches(source).length + 1;
    measurements.add(_FileMeasurement(relative, lines));

    if (lines > _maxProductionFileLines) {
      violations.add(
        '$relative has $lines lines; production files must remain at or below '
        '$_maxProductionFileLines lines.',
      );
    }
    if (relative.startsWith('lib/widgets/') &&
        lines > _maxPresentationFileLines) {
      violations.add(
        '$relative has $lines lines; presentation files must remain at or '
        'below $_maxPresentationFileLines lines.',
      );
    }
    final fileBudget = _fileLineBudgets[relative];
    if (fileBudget != null && lines > fileBudget) {
      violations.add(
        '$relative regressed above its $fileBudget-line decomposition budget '
        '($lines lines).',
      );
    }

    if (relative.startsWith('lib/analytics/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
      _forbidImport(relative, source, '/models.dart', violations);
      _forbidLiveModelField(relative, source, violations);
    }
    if (relative.startsWith('lib/coordinators/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, '/widgets/', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
      _forbidImport(relative, source, '/models.dart', violations);
    }
    if (relative.startsWith('lib/engines/')) {
      _forbidImport(relative, source, '/models.dart', violations);
    }
    if (relative.startsWith('lib/persistence/')) {
      _forbidImport(relative, source, 'app_state.dart', violations);
      _forbidImport(relative, source, '/widgets/', violations);
      _forbidImport(relative, source, 'package:flutter/', violations);
      _forbidImport(relative, source, '/models.dart', violations);
    }
    if (relative.startsWith('lib/widgets/')) {
      _forbidImport(relative, source, 'storage_service.dart', violations);
      _forbidImport(relative, source, '/persistence/', violations);
    }
    if (_ordinaryExtractedModules.contains(relative) ||
        relative.startsWith('lib/widgets/weekly_analytics/') ||
        relative.startsWith('lib/widgets/progress_hub/') ||
        relative.startsWith('lib/widgets/tasks/')) {
      _forbidPartOf(relative, source, violations);
    }
    if (_selectorMigratedFeatureRoots.contains(relative) &&
        source.contains('AppStateProvider.of(context)')) {
      violations.add(
        '$relative must use AppStateSelector plus AppStateProvider.read at its '
        'feature root; broad AppStateProvider.of observation is forbidden.',
      );
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

  _checkMainPageObservation(root, violations);
  _checkReturnContextBoundaries(root, violations);
  _checkVersionSync(root, violations);

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

void _checkReturnContextBoundaries(Directory root, List<String> violations) {
  final resolver = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
    'engines${Platform.pathSeparator}return_context_resolver.dart',
  );
  if (!resolver.existsSync()) return;

  final resolverSource = resolver.readAsStringSync();
  const resolverPath = 'lib/engines/return_context_resolver.dart';
  _forbidImport(resolverPath, resolverSource, 'package:flutter/', violations);
  _forbidImport(resolverPath, resolverSource, 'app_state.dart', violations);
  _forbidImport(resolverPath, resolverSource, '/models', violations);
  _forbidLiveModelField(resolverPath, resolverSource, violations);
  if (resolverSource.contains('DateTime.now(')) {
    violations.add(
      '$resolverPath must receive explicit time instead of reading the wall '
      'clock.',
    );
  }

  final detachedSession = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
    'features${Platform.pathSeparator}return_context${Platform.pathSeparator}'
    'return_context_session.dart',
  );
  if (detachedSession.existsSync()) {
    final source = detachedSession.readAsStringSync();
    const path = 'lib/features/return_context/return_context_session.dart';
    _forbidImport(path, source, 'app_state.dart', violations);
    _forbidImport(path, source, 'storage_service.dart', violations);
    _forbidImport(path, source, '/persistence/', violations);
    _forbidImport(path, source, 'package:hive', violations);
  }

  final presentationFiles = <File>[
    ...Directory(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'features${Platform.pathSeparator}return_context',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
    File(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'widgets${Platform.pathSeparator}return_context_card.dart',
    ),
  ];
  for (final file in presentationFiles.where((file) => file.existsSync())) {
    final path = _relativePath(root, file);
    final source = file.readAsStringSync();
    _forbidImport(path, source, 'storage_service.dart', violations);
    _forbidImport(path, source, '/persistence/', violations);
    _forbidImport(path, source, 'package:hive', violations);
  }

  final persistedSources = <File>[
    ...Directory(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}models',
    ).listSync(recursive: true).whereType<File>(),
    File(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'storage_service.dart',
    ),
    File(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'storage_snapshot.dart',
    ),
    ...Directory(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'persistence',
    ).listSync(recursive: true).whereType<File>(),
  ];
  final persistentDeclaration = RegExp(
    r'^\s*(?:class|enum|mixin)\s+\w*(?:ReturnContext|SavePoint)\w*',
    multiLine: true,
  );
  for (final file in persistedSources.where(
    (file) => file.existsSync() && file.path.endsWith('.dart'),
  )) {
    if (persistentDeclaration.hasMatch(file.readAsStringSync())) {
      violations.add(
        '${_relativePath(root, file)} declares persistent Return Context or '
        'Save Point state; the prototype must remain derived and session-only.',
      );
    }
  }
}

void _checkMainPageObservation(Directory root, List<String> violations) {
  final shell = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
    'widgets${Platform.pathSeparator}main_page${Platform.pathSeparator}'
    'shell.dart',
  );
  final source = shell.readAsStringSync();
  if (source.contains('AppStateProvider.of(context)')) {
    violations.add(
      'MainPage must not broadly observe AppState. Use explicit state '
      'ownership, AppStateProvider.read, or a narrow AppStateSelector '
      'boundary.',
    );
  }
  if (!source.contains('MainPageWorkspaceBoundary(')) {
    violations.add(
      'MainPage must retain its narrow workspace observation boundary.',
    );
  }

  final main = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}main.dart',
  ).readAsStringSync();
  if (!RegExp(r'MainPage\s*\(\s*state\s*:\s*_state').hasMatch(main)) {
    violations.add(
      'The app root must pass its owned AppState explicitly to MainPage.',
    );
  }
}

void _checkVersionSync(Directory root, List<String> violations) {
  final pubspec = File(
    '${root.path}${Platform.pathSeparator}pubspec.yaml',
  ).readAsStringSync();
  final utils = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}utils.dart',
  ).readAsStringSync();
  violations.addAll(
    versionSyncViolations(pubspecSource: pubspec, versionSource: utils),
  );
}

void _forbidPartOf(String path, String source, List<String> violations) {
  if (RegExp(r'^\s*part\s+of\s+', multiLine: true).hasMatch(source)) {
    violations.add(
      '$path is an extracted ordinary module and must not regress to part of.',
    );
  }
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
    r'^\s*final\s+(Task|Skill|SkillTreeNode|WeeklyGoal|HistoryEntry)\??\s+\w+\s*;',
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
