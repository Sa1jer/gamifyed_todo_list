import 'dart:io';

/// Runs the repository's non-mutating local validation gate on every platform.
Future<void> main() async {
  final root = Directory.current;
  final commands = <({String executable, List<String> arguments})>[
    (
      executable: 'dart',
      arguments: [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'lib',
        'test',
      ],
    ),
    (executable: 'flutter', arguments: ['analyze']),
    (
      executable: 'flutter',
      arguments: ['test', '-r', 'expanded', '--timeout', '30s'],
    ),
    (executable: 'git', arguments: ['diff', '--check']),
  ];

  for (final command in commands) {
    stdout.writeln('\n> ${command.executable} ${command.arguments.join(' ')}');
    final process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: root.path,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      exit(exitCode);
    }
  }
}
