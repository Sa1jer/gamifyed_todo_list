import 'package:flutter_test/flutter_test.dart';

import '../tool/version_sync.dart';

void main() {
  test('version parser tolerates whitespace and comments', () {
    expect(
      parsePubspecVersion('name: sample\n  version: 1.3.64+1 # release\n'),
      '1.3.64+1',
    );
    expect(
      parseDisplayedVersionLabel(
        "const String kAppVersionLabel = 'v1.3.64+1';",
      ),
      'v1.3.64+1',
    );
  });

  test('version guard rejects drift with an actionable message', () {
    final violations = versionSyncViolations(
      pubspecSource: 'version: 1.3.65+1',
      versionSource: "const String kAppVersionLabel = 'v1.3.64+1';",
    );

    expect(violations, hasLength(1));
    expect(violations.single, contains('Expected v1.3.65+1'));
  });
}
