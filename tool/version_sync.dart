String? parsePubspecVersion(String source) {
  final match = RegExp(
    r'^\s*version\s*:\s*([^\s#]+)',
    multiLine: true,
  ).firstMatch(source);
  return match?.group(1);
}

String? parseDisplayedVersionLabel(String source) {
  final match = RegExp(
    r'''const\s+String\s+kAppVersionLabel\s*=\s*['"]([^'"]+)['"]\s*;''',
  ).firstMatch(source);
  return match?.group(1);
}

List<String> versionSyncViolations({
  required String pubspecSource,
  required String versionSource,
}) {
  final pubspecVersion = parsePubspecVersion(pubspecSource);
  final displayedVersion = parseDisplayedVersionLabel(versionSource);
  if (pubspecVersion == null) {
    return const ['Unable to parse the version field from pubspec.yaml.'];
  }
  if (displayedVersion == null) {
    return const ['Unable to parse kAppVersionLabel from lib/utils.dart.'];
  }
  final expected = 'v$pubspecVersion';
  if (displayedVersion == expected) return const [];
  return [
    'Displayed app version $displayedVersion does not match pubspec version '
        '$pubspecVersion. Expected $expected.',
  ];
}
